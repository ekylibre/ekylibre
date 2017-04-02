# coding: utf-8

module LaGraineInformatique
  module Vinifera
    class SalesExchanger < ActiveExchanger::Base
      def import
        rows = CSV.read(file, headers: true, encoding: 'cp1252', col_sep: ';')
        w.count = rows.count

        country = Preference[:country]

        # FILE STRUCTURE
        # 0 Client code
        # 1 Delivery date (JJ/MM/0AAA format !!!)
        # 3 sale number
        # 4 sale item number
        # number of variant (6-7-8)
        # 6 appelation (first line)
        # 7 year (second line)
        # 8 unity for sale (third line)

        rows.each do |row|
          r = {
            client_code: row[0].blank? ? nil : row[0].to_s,
            original_date: row[1].blank? ? nil : row[1].to_s,
            sale_number: row[3].blank? ? nil : row[3].to_s,
            sale_item_number: row[4].blank? ? nil : row[4].to_s,
            appelation: row[6].blank? ? nil : row[6].to_s,
            year: row[7].blank? ? nil : row[7].to_s,
            unity: row[8].blank? ? nil : row[8].to_s,
            quantity: (row[10].blank? ? nil : row[10].tr(',', '.').to_d),
            unit_pretax_amount: (row[11].blank? ? nil : row[11].tr(',', '.').to_d),
            vat_rate: (row[28].blank? ? nil : row[28].tr(',', '.').to_d)
          }.to_struct

          if r.original_date
            day = r.original_date[0..1].to_i
            month = r.original_date[3..4].to_i
            year = 1900 + r.original_date[7..9].to_i
            sale_invoiced_at = Date.new(year, month, day).to_time
            w.info sale_invoiced_at.inspect.green
          end

          # find an entity link to this client
          entity = Entity.where(description: r.client_code).first if r.client_code

          # find a the external number of the product

          variant_number = nil
          variant_number = r.appelation + '-' + r.year + '-' + r.unity if r.appelation && r.year && r.unity
          w.info variant_number.inspect.red

          # find a variant link to this external number
          if variant_number
            # find variant in DB by number (external number)
            unless variant = ProductNatureVariant.find_by(number: variant_number)
              w.warn "No way to find #{variant_number} in variant DB"
              # fail "Import variant first"
            end
          end

          # find or create a purchase
          if entity && sale_invoiced_at && r.sale_number
            # see if purchase exist anyway
            unless sale = Sale.where(reference_number: r.sale_number).first
              sale = Sale.create!(invoiced_at: sale_invoiced_at,
                                  reference_number: r.sale_number,
                                  client_id: entity.id,
                                  nature: SaleNature.actives.first)
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
      end
    end
  end
end
