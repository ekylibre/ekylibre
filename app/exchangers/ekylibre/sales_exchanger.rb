module Ekylibre
  class SalesExchanger < ActiveExchanger::Base
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size
      sale_ids = []

      rows.each do |row|
        r = {
          invoiced_at:        (row[0].blank? ? nil : Date.parse(row[0].to_s)),
          client_full_name: (row[1].blank? ? nil : row[1]),
          reference_number:   (row[2].blank? ? nil : row[2].upcase),
          variant_code: (row[3].blank? ? nil : row[3]),
          quantity: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
          unit_pretax_amount: (row[5].blank? ? nil : row[5].tr(',', '.').to_d),
          vat_rate: (row[6].blank? ? nil : row[6].tr(',', '.').to_d),
          description: (row[7].blank? ? '' : row[7].to_s),
          # Extra infos
          document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2]}".tr(' ', '-')
        }.to_struct

        country = Preference[:country]

        # find an entity
        if r.client_full_name
          entity = Entity.where('full_name ILIKE ?', r.client_full_name).first
        end

        # find or import a variant
        if r.variant_code
          variant = ProductNatureVariant.where(name: r.variant_code).first || ProductNatureVariant.where(work_number: r.variant_code).first
          unless variant
            if Nomen::ProductNatureVariant.find(r.variant_code.to_sym)
              variant = ProductNatureVariant.import_from_nomenclature(r.variant_code.to_sym)
            end
          end
        end

        # find or create a purchase
        if entity && r.invoiced_at && r.reference_number
          # see if purchase exist anyway
          unless sale = Sale.where(reference_number: r.reference_number).first
            sale = Sale.create!(invoiced_at: r.invoiced_at,
                                reference_number: r.reference_number,
                                client_id: entity.id,
                                nature: SaleNature.actives.first,
                                description: r.description)
            sale_ids << sale.id
          end
        end

        # find or create a tax
        # TODO: search country before for good tax request (country and amount)
        # country via entity if information exist
        if r.vat_rate && country
          item = Nomen::Tax.where(country: country.to_sym, amount: r.vat_rate).first
          if item
            unless sale_item_tax = Tax.where(reference_name: item.name).first
              sale_item_tax = Tax.import_from_nomenclature(item.name)
            end
          end
        end

        # find or create a purchase line
        if sale && variant && r.unit_pretax_amount && r.quantity && sale_item_tax
          unless sale_item = SaleItem.where(sale_id: sale.id, pretax_amount: r.pretax_amount, variant_id: variant.id).first
            sale.items.create!(quantity: r.quantity, tax: sale_item_tax, unit_pretax_amount: r.unit_pretax_amount, variant: variant)
          end
        end

        w.check_point
      end
      # Restart counting
      added_sales = Sale.where(id: sale_ids)
      w.reset! added_sales.count, :yellow

      # change status of all new added purchases
      added_sales.each do |sale|
        sale.propose if sale.draft?
        sale.confirm
        sale.invoice(sale.invoiced_at)
        w.check_point
      end
    end
  end
end
