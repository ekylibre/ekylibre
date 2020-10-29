module Ekylibre
  class PurchasesExchanger < ActiveExchanger::Base
    self.deprecated = true

    def initialize(file, supervisor, options = {})
      super file, supervisor
      @attachments_dir = options['attachments_path']
      @attachments_dir &&= Pathname.new(@attachments_dir)
    end

    def check
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      purchase_ids = []
      now = Time.zone.now
      valid = true

      vinfos = 9 - 1

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"

        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          supplier_full_name: (row[1].blank? ? nil : row[1]),
          reference_number:   (row[2].blank? ? nil : row[2].upcase),
          variant_code:       (row[3].blank? ? nil : row[3]),
          role:         (row[4].blank? ? 'merchandise' : row[4]),
          quantity:           (row[5].blank? ? nil : row[5].tr(',', '.').to_d),
          unit_pretax_amount: (row[6].blank? ? nil : row[6].tr(',', '.').to_d),
          vat_percentage:     (row[7].blank? ? nil : row[7].tr(',', '.').to_d),
          depreciate:         %w[1 t true yes ok].include?(row[8].to_s.strip.downcase),
          # Variant definition
          variant: {
            variety:                 row[vinfos + 1],
            product_account:         row[vinfos + 2],
            charge_account:          row[vinfos + 3],
            fixed_asset_account: row[vinfos + 4],
            fixed_asset_allocation_account: row[vinfos + 5],
            fixed_asset_expenses_account:   row[vinfos + 6]
          }
        }.to_struct

        # Check date
        unless r.invoiced_at
          w.error "No date given at #{prompt}"
          valid = false
        end

        # Check variant
        unless r.variant_code
          w.error "Variant identifiant must be given at #{prompt}"
          valid = false
        end

        # Check supplier
        unless supplier = Entity.where('full_name ILIKE ?', r.supplier_full_name).first
          w.error "Cannot find supplier #{r.supplier_full_name} at #{prompt}"
          valid = false
        end
      end
      valid
    end

    def import
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      purchase_ids = []
      now = Time.zone.now

      vinfos = 9 - 1

      rows.each_with_index do |row, index|
        line_index = index + 2

        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          supplier_full_name: (row[1].blank? ? nil : row[1]),
          reference_number:   (row[2].blank? ? nil : row[2].upcase),
          variant_code:       (row[3].blank? ? nil : row[3]),
          role:               (row[4].blank? ? 'merchandise' : row[4]),
          quantity:           (row[5].blank? ? nil : row[5].tr(',', '.').to_d),
          unit_pretax_amount: (row[6].blank? ? nil : row[6].tr(',', '.').to_d),
          vat_percentage:     (row[7].blank? ? nil : row[7].tr(',', '.').to_d),
          depreciate:         %w[1 t true yes ok].include?(row[8].to_s.strip.downcase),
          # Variant definition
          variant: {
            variety:                 row[vinfos + 1],
            product_account:         row[vinfos + 2],
            charge_account:          row[vinfos + 3],
            fixed_asset_account: row[vinfos + 4],
            fixed_asset_allocation_account: row[vinfos + 5],
            fixed_asset_expenses_account:   row[vinfos + 6]
          },

          # Extra infos
          document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2]}".tr(' ', '-'),
          description: now.l
        }.to_struct

        # Find or import a variant
        unless r.variant_code
          raise "Variant identifiant must be given at line #{line_index}"
        end
        unless variant = ProductNatureVariant.find_by(work_number: r.variant_code)
          if Nomen::ProductNatureVariant.find(r.variant_code)
            variant = ProductNatureVariant.import_from_nomenclature(r.variant_code)
          else
            if r.variant[:fixed_asset_account]
              suffix = r.variant[:fixed_asset_account][1..-1]
              r.variant[:fixed_asset_allocation_account] ||= "28#{suffix}"
              r.variant[:fixed_asset_expenses_account] ||= "68#{suffix}"
              r.variant[:fixed_asset_depreciation_method] ||= :linear
              r.variant[:fixed_asset_depreciation_percentage] ||= 15
            end
            %w[product charge fixed_asset fixed_asset_allocation fixed_asset_expenses].each do |type|
              key = "#{type}_account".to_sym
              account_infos = r.variant[key].to_s.split(':')
              account_number = account_infos.shift
              account_name = account_infos.shift
              next if account_number.blank?
              unless account = Account.find_by(number: account_number.strip)
                account = Account.create!(name: account_name || account_number, number: account_number)
              end
              r.variant[key] = account
            end
            attrs = r.variant.select { |k, v| v.present? && k != :variety }
            attrs[:name] = r.variant_code
            attrs[:saleable] = true if attrs[:product_account]
            attrs[:purchasable] = true if attrs[:charge_account]
            attrs[:depreciable] = true if attrs[:fixed_asset_account]
            attrs[:type] = variant.type.gsub /Variant/, 'Category'
            unless category = ProductNatureCategory.find_by(attrs)
              category = ProductNatureCategory.create!(attrs.merge(active: true, pictogram: :undefined))
            end
            attrs[:variety] = r.variant[:variety] || :product

            n_attrs[:name] = attrs[:name]
            n_attrs[:variety] = attrs[:variety]
            n_attrs[:population_counting] = :decimal
            n_attrs[:type] = variant.type.gsub /Variant/, 'Type'
            nature = ProductNature.find_or_create_by!(n_attrs)

            unless variant = nature.variants.first
              type = category.article_type || nature.variant_type
              variant = nature.variants.create!(name: attrs[:name], variety: attrs[:variety], unit_name: 'Unit', category: category, type: type)
            end
          end
        end
        raise "Unknown variant at line #{line_index}" unless variant

        # Find or create a purchase
        # if supplier and r.invoiced_at and r.reference_number
        # see if purchase exist anyway
        unless purchase = PurchaseInvoice.find_by(reference_number: r.reference_number)
          # Find supplier
          unless supplier = Entity.where('full_name ILIKE ?', r.supplier_full_name).first
            raise "Cannot find supplier #{r.supplier_full_name} at line #{line_index}"
          end
          raise "Missing invoice date at line #{line_index}" unless r.invoiced_at
          purchase = PurchaseInvoice.create!(
            planned_at: r.invoiced_at,
            invoiced_at: r.invoiced_at,
            reference_number: r.reference_number,
            supplier: supplier,
            nature: PurchaseNature.actives.first,
            description: r.description
          )
          if @attachments_dir.present?
            attachment_potential_path = @attachments_dir.join(purchase.supplier.name.parameterize,
                                                              purchase.reference_number + ".*")
            attachment_paths = Dir.glob(attachment_potential_path)
            attachment_paths.each do |attachment_path|
              doc = Document.new(file: File.open(attachment_path))
              purchase.attachments.create!(document: doc)
            end
          end
          purchase_ids << purchase.id
        end

        # Find or create a tax
        # country via supplier if information exist
        raise "Missing VAT at line #{line_index}" unless r.vat_percentage

        tax = Tax.find_on(purchase.invoiced_at.to_date, country: purchase.supplier.country.to_sym, amount: r.vat_percentage)
        raise "No tax found for given #{r.vat_percentage}" unless tax

        # find or create a purchase line
        unless purchase.items.find_by(pretax_amount: r.pretax_amount, variant_id: variant.id, tax_id: tax.id)
          raise "Missing quantity at line #{line_index}" unless r.quantity
          # puts r.variant_code.inspect.red

          purchase.items.create!(role: r.role, quantity: r.quantity, tax: tax, unit_pretax_amount: r.unit_pretax_amount, variant: variant, fixed: r.depreciate)
        end

        w.check_point
      end

    end
  end
end
