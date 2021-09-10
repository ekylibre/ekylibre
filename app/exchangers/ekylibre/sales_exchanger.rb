# frozen_string_literal: true

module Ekylibre
  class SalesExchanger < ActiveExchanger::Base
    category :sales
    vendor :ekylibre

    def initialize(file, supervisor, options = {})
      super file, supervisor
      @attachments_dir = options['attachments_path']
      @attachments_dir &&= Pathname.new(@attachments_dir)
    end

    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      sales = {}

      rows.each do |row|
        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          client_full_name: (row[1].blank? ? nil : row[1]),
          reference_number:   (row[2].blank? ? nil : row[2].upcase),
          variant_code: (row[3].blank? ? nil : row[3]),
          quantity: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
          unit_pretax_amount: (row[5].blank? ? nil : row[5].tr(',', '.').to_d),
          vat_percentage: (row[6].blank? ? nil : row[6].tr(',', '.').to_d),
          description: (row[7].blank? ? '' : row[7].to_s),
          # Extra infos
          document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2]}".tr(' ', '-')
        }.to_struct

        country = Preference[:country]

        # find an entity
        if r.client_full_name
          entity = Entity.where('full_name ILIKE ?', r.client_full_name).first
        end

        # find or create a purchase
        if entity && r.invoiced_at && r.reference_number
          # see if sales exist
          unless sales[r.reference_number]
            sales[r.reference_number] = {
              invoiced_at: r.invoiced_at,
              reference_number: r.reference_number,
              client_id: entity.id,
              nature: SaleNature.actives.first,
              description: r.description,
              items_attributes: {}
            }
          end
        end

        # find or create a tax
        # country via entity if information exist
        raise "Missing VAT at line #{line_index}" unless r.vat_percentage

        sale_item_tax = Tax.find_on(r.invoiced_at.to_date, country: country.to_sym, amount: r.vat_percentage)
        raise "No tax found for given #{r.vat_percentage}" unless sale_item_tax

        # find or import a variant
        if r.variant_code
          variant = ProductNatureVariant.where(name: r.variant_code).first || ProductNatureVariant.where(work_number: r.variant_code).first
          unless variant
            if MasterVariant.find_by(reference_name: r.variant_code.to_s)
              variant = ProductNatureVariant.import_from_lexicon(r.variant_code.to_s)
            end
          end
        end

        # find or create a purchase line
        if variant && r.unit_pretax_amount && r.quantity && sale_item_tax
          conditioning_data = variant.guess_conditioning
          id = (sales[r.reference_number][:items_attributes].keys.max || 0) + 1
          sales[r.reference_number][:items_attributes][id] = {
            amount: nil,
            pretax_amount: nil,
            conditioning_quantity: r.quantity * conditioning_data[:quantity],
            conditioning_unit: conditioning_data[:unit],
            tax: sale_item_tax,
            unit_pretax_amount: r.unit_pretax_amount,
            variant: variant,
            compute_from: :unit_pretax_amount
          }
        end

        w.check_point
      end

      w.reset! sales.values.count, :yellow
      sale_ids = []
      # Restart counting
      sales.values.each do |sale|
        s = Sale.create!(sale)
        sale_ids << s.id
        w.check_point
      end

      added_sales = Sale.where(id: sale_ids)
      w.reset! added_sales.count, :yellow
      # change status of all new added sales
      added_sales.each do |sale|
        sale.propose if sale.draft?
        sale.confirm(sale.invoiced_at)
        sale.invoice(sale.invoiced_at)
        link_document(sale)
        w.check_point
      end
    end

    private

      def link_document(sale)
        if @attachments_dir.present?
          attachment_potential_path = @attachments_dir.join(sale.client.name.parameterize,
                                                            sale.reference_number + ".*")
          attachment_paths = Dir.glob(attachment_potential_path)
          attachment_paths.each do |attachment_path|
            doc = Document.new(file: File.open(attachment_path))
            sale.attachments.create!(document: doc)
          end
        end
      end

  end
end
