module Vivescia
  # Exchanger to import COFTW.isa files from IsaCompta software
  class PurchaseExchanger < ActiveExchanger::Base
    category :purchases
    vendor :vivescia

    def check
      SVF::EdiFactInvoic.parse(file)
    rescue SVF::InvalidSyntax
      return false
    end

    def import
      # path = "/home/djoulin/projects/integration-cer-cneidf/db/first_runs/gaec-hureau/vivescia/appros.edi"
      # file = File.open(path)

      # please refer to lib/svf/norms/edi/fact_invoic.yml

      units_transcode = { 'KGM' => :kilogram,
                          'DTN' => :quintal,
                          'KK' => :quintal,
                          'GRM' => :gram,
                          'TNE' => :ton,
                          'EA' => :unity,
                          'NAR' => :unity,
                          'DOS' => :unity,
                          'PCE' => :unity,
                          'MTR' => :meter,
                          'KMT' => :kilometer,
                          'LTR' => :liter,
                          'MTQ' => :cubic_meter }

      # Load hash to transcode EDI items categories to variant
      here = Pathname.new(__FILE__).dirname
      inputs_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('inputs.csv'), headers: true) do |row|
        inputs_transcode[row[0]] = row[1].to_sym
      end

      # use edi_purchase_item.work_number on LIN segment
      catalog_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('catalog.csv'), headers: true) do |row|
        catalog_transcode[row[1].to_s] = { name: row[4], unit: units_transcode[row[5]], account_number: row[6], account_name: row[7] }
      end

      begin
        edifact = SVF::EdiFactInvoic.parse(file)
      rescue SVF::InvalidSyntax
        raise ActiveExchanger::NotWellFormedFileError
      end

      w.count = edifact.purchases.count

      sender_name = 'Vivescia'
      sender = Entity.find_by(last_name: sender_name) ||
               Entity.where('last_name ILIKE ?', sender_name).first ||
               Entity.create!(nature: :organization,
                              last_name: sender_name,
                              supplier: true, client: true)

      edifact.purchases.each do |edi_purchase|
        ########################################
        #  purchase and discount
        ########################################

        if %w[AFF AFA ACF].any? { |word| edi_purchase.header.purchase_code.include?(word) }
          unless purchase = PurchaseInvoice.find_by(reference_number: edi_purchase.header.purchase_number)
            purchase = PurchaseInvoice.create!(
              planned_at: Time.parse(edi_purchase.header.purchase_printed_on),
              invoiced_at: Time.parse(edi_purchase.header.purchase_printed_on),
              reference_number: edi_purchase.header.purchase_number,
              supplier: sender,
              nature: PurchaseNature.actives.first,
              description: edi_purchase.header.purchase_title
            )

            edi_purchase.items.each do |edi_purchase_item|
              # transcode detail number in EDI into variant nomen
              w.info "EDI work number : #{edi_purchase_item.work_number}".yellow
              pivot = catalog_transcode[edi_purchase_item.work_number.to_s]
              pivot ||= catalog_transcode[edi_purchase_item.detail.description.to_s]
              unless pivot
                w.error "No item in pivot availables for #{edi_purchase_item.work_number}".red
                next
              end
              account_number = pivot[:account_number].sub!(/0+$/, '')
              w.info "pivot : #{pivot}".yellow
              w.info "account_number : #{account_number}".yellow

              # try to find the correct variant from id of provider
              product_nature_variant = ProductNatureVariant.where('providers ->> ? = ?', sender.id, edi_purchase_item.work_number).first if edi_purchase_item.work_number.present?
              # try to find the correct variant from name
              product_nature_variant ||= ProductNatureVariant.where('name ILIKE ?', edi_purchase_item.detail.description).first if edi_purchase_item.detail && edi_purchase_item.detail.description.present?
              # create the variant
              if !product_nature_variant && pivot
                # find the correct category of product bases on pivot
                account = Account.find_or_create_by_number(account_number) do |a|
                  a.name = pivot[:account_name]
                end
                w.info "account name : #{account.name}".yellow
                # find category by charge or product account
                pnc = ProductNatureCategory.where(charge_account_id: account.id).first
                pnc ||= ProductNatureCategory.where(product_account_id: account.id).first
                unless pnc
                  w.error "No categories availables for account : #{account.name}".red
                  next
                end
                pnv = ProductNatureVariant.where(category_id: pnc.id).first
                if pnv
                  product_nature_variant = ProductNatureVariant.import_from_nomenclature(pnv.reference_name, true)
                  product_nature_variant.providers = { sender.id => edi_purchase_item.work_number } if edi_purchase_item.work_number.present?
                  product_nature_variant.name = pivot[:name]
                  product_nature_variant.unit_name = Nomen::Unit[pivot[:unit]].human_name
                  product_nature_variant.save!
                else
                  w.error "No variant availables for EDI work number : #{edi_purchase_item.work_number}".red
                end
              end

              item = if edi_purchase_item.tax
                       Nomen::Tax.find_by(country: purchase.supplier.country.to_sym, amount: edi_purchase_item.tax.rate.to_f)
                     else
                       Nomen::Tax.find_by(country: purchase.supplier.country.to_sym, nature: :null_vat, amount: 0.0)
                     end
              tax = Tax.import_from_nomenclature(item.name)

              next unless tax && product_nature_variant

              w.info "quantity : #{edi_purchase_item.quantity}".yellow
              w.info "price unit : #{edi_purchase_item.price_unit}".yellow

              # set price unit to 1 if 0

              qty = if edi_purchase_item.quantity == 0.0
                      if edi_purchase.header.purchase_code.include?('AFA') || edi_purchase.header.purchase_code.include?('ACF')
                        -1.0
                      else
                        1.0
                            end
                    else
                      if edi_purchase.header.purchase_code.include?('AFA') || edi_purchase.header.purchase_code.include?('ACF')
                        -edi_purchase_item.quantity
                      else
                        edi_purchase_item.quantity
                            end
                    end

              # set unit_pretax_amount to pretax_amount if 0
              upta = if edi_purchase_item.price_unit == 0.0
                       edi_purchase_item.pretax_amount
                     else
                       edi_purchase_item.price_unit
                     end

              purchase.items.create!(quantity: qty,
                                     tax: tax,
                                     unit_pretax_amount: upta,
                                     variant: product_nature_variant)
            end
          end

        ########################################
        #  sale
        ########################################

        elsif ['C F', 'CCF', 'CKF'].any? { |word| edi_purchase.header.purchase_code.include?(word) }

          unless sale = Sale.find_by(reference_number: edi_purchase.header.purchase_number)

            w.info "printed_on : #{edi_purchase.header.purchase_printed_on}".yellow
            w.info "purchase_number : #{edi_purchase.header.purchase_number}".yellow

            sale = Sale.create!(
              invoiced_at: Time.parse(edi_purchase.header.purchase_printed_on),
              reference_number: edi_purchase.header.purchase_number,
              client: sender,
              nature: SaleNature.actives.first,
              description: edi_purchase.header.purchase_title
            )

            edi_purchase.items.each do |edi_sale_item|
              # transcode detail number in EDI into variant nomen
              w.info "EDI work number : #{edi_sale_item.work_number}".yellow
              pivot = catalog_transcode[edi_sale_item.work_number.to_s]
              pivot ||= catalog_transcode[edi_sale_item.detail.description.to_s]
              unless pivot
                w.error "No item in pivot availables for #{edi_sale_item.work_number}".red
                next
              end
              account_number = pivot[:account_number].sub!(/0+$/, '')
              w.info "pivot : #{pivot}".yellow
              w.info "account_number : #{account_number}".yellow

              # try to find the correct variant from id of provider
              product_nature_variant = ProductNatureVariant.where('providers ->> ? = ?', sender.id, edi_sale_item.work_number).first if edi_sale_item.work_number.present?
              # try to find the correct variant from name
              product_nature_variant ||= ProductNatureVariant.where('name ILIKE ?', edi_sale_item.detail.description).first if edi_sale_item.detail && edi_sale_item.detail.description.present?
              # create the variant
              if !product_nature_variant && pivot
                # find the correct category of product bases on pivot
                account = Account.find_or_create_by_number(account_number) do |a|
                  a.name = pivot[:account_name]
                end
                w.info "account name : #{account.name}".yellow
                # find category by charge or product account
                pnc = ProductNatureCategory.where(charge_account_id: account.id).first
                pnc ||= ProductNatureCategory.where(product_account_id: account.id).first
                unless pnc
                  w.error "No categories availables for account : #{account.name}".red
                  next
                end
                pnv = ProductNatureVariant.where(category_id: pnc.id).first
                if pnv
                  product_nature_variant = ProductNatureVariant.import_from_nomenclature(pnv.reference_name, true)
                  product_nature_variant.providers = { sender.id => edi_sale_item.work_number } if edi_sale_item.work_number.present?
                  product_nature_variant.name = pivot[:name]
                  product_nature_variant.unit_name = Nomen::Unit[pivot[:unit]].human_name
                  product_nature_variant.save!
                else
                  w.error "No variant availables for EDI work number : #{edi_sale_item.work_number}".red
                end
              end

              item = if edi_sale_item.tax
                       Nomen::Tax.find_by(country: sale.client.country.to_sym, amount: edi_sale_item.tax.rate.to_f)
                     else
                       Nomen::Tax.find_by(country: sale.client.country.to_sym, nature: :null_vat, amount: 0.0)
                     end
              tax = Tax.import_from_nomenclature(item.name)

              # set unit_pretax_amount in correct sign
              if edi_sale_item.sign && edi_sale_item.sign == 'A'
                upta = -edi_sale_item.price_unit
                pta = -edi_sale_item.pretax_amount
              elsif edi_sale_item.client_work_number_type && (edi_sale_item.client_work_number_type == 'TA' || edi_sale_item.client_work_number_type == 'TC')
                upta = -edi_sale_item.price_unit
                pta = -edi_sale_item.pretax_amount
              else
                upta = edi_sale_item.price_unit
                pta = edi_sale_item.pretax_amount
                     end

              if edi_sale_item.quantity > 0.0
                qty = edi_sale_item.quantity
              elsif edi_sale_item.pretax_amount > 0.0 && upta > 0.0
                qty = (edi_sale_item.pretax_amount / upta).to_d
              elsif edi_sale_item.pretax_amount > 0.0 && upta == 0.0 && edi_sale_item.quantity == 0.0
                qty = 1.0
                upta = edi_sale_item.pretax_amount
              end

              # check good quantity on EDI based on pretax_amount
              a = (qty * upta).abs
              b = pta.abs
              qty = (pta / upta).abs if a.to_i != b.to_i

              next if sale_item = SaleItem.where(
                sale_id: sale.id,
                pretax_amount: edi_sale_item.pretax_amount,
                variant_id: product_nature_variant.id
              ).first
              sale.items.create!(
                quantity: qty,
                tax: tax,
                amount: nil,
                pretax_amount: nil,
                unit_pretax_amount: upta,
                variant: product_nature_variant,
                compute_from: :unit_pretax_amount
              )
            end
            # sale.reload
            # sale.propose if sale.draft?
            # sale.confirm
            # sale.invoice(sale.invoiced_at)

          end

        end
        w.check_point
      end
    end
  end
end
