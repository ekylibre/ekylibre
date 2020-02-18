module PanierLocal
  class SalesExchanger < ActiveExchanger::Base
    def check
      # Imports sales entries into sales to make accountancy in CSV format
      # filename example : ECRITURES.CSV
      # Columns are:
      #  0 - A: journal_entry_items_line : "1"
      #  1 - B: printed_on : "01/01/2017"
      #  2 - C: journal code : "70"
      #  3 - D: journal nature : "FACTURE"
      #  4 - E: account number : "34150000"
      #  5 - F: entity name : "AB EPLUCHES"
      #  6 - G: entity number : "133"
      #  7 - H: journal_entry number : "842"
      #  8 - I: journal_entry label : "Facture Aout 2019"
      #  9 - J: amount : '44,24'
      #  10 - K: sens : 'D'
      #  11 - L: pretax_amount : '36,87'
      #  12 - L: tax_rate : '20'
      #  13 - M: quantity : '104'

      source = File.read(file)
      detection = CharlockHolmes::EncodingDetector.detect(source)
      rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: ';')
      w.count = rows.size
      valid = true

      last_line = rows.size - 1

      fy_start = FinancialYear.at(Date.parse(rows.first[1].to_s))
      fy_stop = FinancialYear.at(Date.parse(rows[last_line][1].to_s))
      unless fy_start && fy_stop
        w.warn 'Need a FinancialYear'
        valid = false
      end

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        r = {
          sale_item_line: (row[0].blank? ? nil : row[0]),
          invoiced_at:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
          journal_nature: (row[3].blank? ? nil : row[3].to_s),
          account_number:   (row[4].blank? ? nil : row[4].upcase),
          entity_name: (row[5].blank? ? nil : row[5].to_s),
          entity_code: (row[6].blank? ? nil : row[6].to_s),
          sale_reference_number: (row[7].blank? ? nil : row[7].to_s),
          sale_description: (row[8].blank? ? nil : row[8].to_s),
          sale_item_amount: (row[9].blank? ? nil : row[9].tr(',', '.').to_f),
          sale_item_sens: (row[10].blank? ? nil : row[10].to_s),
          sale_item_pretax_amount: (row[11].blank? ? nil : row[11].tr(',', '.').to_f),
          vat_percentage: (row[12].blank? ? nil : row[12].tr(',', '.').to_d),
          quantity: (row[13].blank? ? nil : row[13].tr(',', '.').to_d)
        }.to_struct

        unless r.sale_item_amount >= 0.0
          valid = false
        end

        if r.invoiced_at.nil? || r.entity_name.nil? || r.entity_code.nil? || r.sale_reference_number.nil?
          valid = false
        end

        w.info valid.inspect.green

      end
      valid
    end

    def import
      source = File.read(file)
      detection = CharlockHolmes::EncodingDetector.detect(source)
      rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: ';')
      w.count = rows.size
      # create or find journal for sale nature
      journal = Journal.find_or_create_by(code: 'PALO', nature: 'sales', name: 'Panier Local')
      catalog = Catalog.find_or_create_by(code: 'PALO', currency: 'EUR', usage: 'sale', name: 'Panier Local')
      # create or find sale_nature
      sale_nature = SaleNature.find_or_create_by(name: "Vente en ligne - Panier Local", catalog_id: catalog.id, currency: 'EUR', payment_delay: '30 days', journal_id: journal.id)

      country = Preference[:country]
      sale_ids = []
      variant = nil
      tax = nil
      quantity = nil
      pretax_amount = nil
      tax_amount = nil
      amount = nil


      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        r = {
          sale_item_line: (row[0].blank? ? nil : row[0]),
          invoiced_at:        (row[1].blank? ? nil : Date.parse(row[1].to_s)),
          journal_nature: (row[3].blank? ? nil : row[3].to_s),
          account_number:   (row[4].blank? ? nil : row[4].upcase),
          entity_name: (row[5].blank? ? nil : row[5].to_s),
          entity_code: (row[6].blank? ? nil : row[6].to_s),
          sale_reference_number: (row[7].blank? ? nil : row[7].to_s),
          sale_description: (row[8].blank? ? nil : row[8].to_s),
          sale_item_amount: (row[9].blank? ? nil : row[9].tr(',', '.').to_f),
          sale_item_sens: (row[10].blank? ? nil : row[10].to_s),
          sale_item_pretax_amount: (row[11].blank? ? nil : row[11].tr(',', '.').to_f),
          vat_percentage: (row[12].blank? ? nil : row[12].tr(',', '.').to_f),
          quantity: (row[13].blank? ? 1.0 : row[13].tr(',', '.').to_f)
        }.to_struct

        next if r.sale_item_amount == 0.0

        # find or create an entity
        if r.entity_name && r.account_number && r.account_number.start_with?('411')
          entity = Entity.where('codes ->> ? = ?', 'panier_local', r.entity_code).first
          last_name = r.entity_name.mb_chars.capitalize
          unless entity
            # check entity account
            acc = Account.find_or_initialize_by(number: r.account_number)
            attributes = {name: r.entity_name}
            attributes[:centralizing_account_name] = r.account_number.start_with?('401') ? 'suppliers' : 'clients'
            attributes[:nature] = 'auxiliary'
            aux_number = r.account_number[3, r.account_number.length]
            if aux_number.match(/\A0*\z/).present?
              w.info "We can't import auxiliary number #{aux_number} with only 0. Mass change number in your file before importing"
              attributes[:auxiliary_number] = '00000A'
            else
              attributes[:auxiliary_number] = aux_number
            end
            acc.attributes = attributes
            acc.save!
            w.info "account saved ! : #{acc.label.inspect.red}"
            # check entity
            w.info "Create entity and link account"
            entity = Entity.where('last_name ILIKE ?', last_name).first
            entity ||= Entity.new
            entity.nature = :organization
            entity.last_name = last_name
            entity.codes = { 'panier_local' => r.entity_code }
            entity.active = true
            entity.client = true
            entity.client_account_id = acc.id
            entity.save!
            w.info "Entity created ! : #{entity.full_name.inspect.red}"
          end
        end

        sale = Sale.where('providers ->> ? = ?', 'panier_local', r.sale_reference_number).first
        unless sale
          sale = Sale.create!(
            invoiced_at: r.invoiced_at,
            reference_number: r.sale_reference_number,
            client_id: entity.id,
            nature: sale_nature,
            description: r.sale_description,
            providers: {'panier_local' => r.sale_reference_number, 'import_id' => options[:import_id]}
          )
          sale_ids << sale.id
        end

        # check vat account and amounts
        if r.account_number.start_with?('445') && r.vat_percentage && r.invoiced_at
          global_pretax_amount = r.sale_item_pretax_amount
          global_tax_amount = r.sale_item_amount
          clean_tax_account_number = r.account_number[0, Preference[:account_number_digits]]
          tax_account = Account.find_or_create_by_number(clean_tax_account_number)
          tax = Tax.find_by(amount: r.vat_percentage, collect_account_id: tax_account.id)
          unless tax
            tax = Tax.find_by(amount: r.vat_percentage, country: country.to_sym)
            tax ||= Tax.find_on(r.invoiced_at.to_date, country: country.to_sym, amount: r.vat_percentage)
            tax.collect_account_id = tax_account.id
            tax.active = true
            tax.save!
          end
          raise "No tax found for given #{r.vat_percentage}" unless tax
          global_amount = global_pretax_amount + global_tax_amount
        end

        # check product account, quantity and variant
        if r.account_number.start_with?('7')
          clean_account_number = r.account_number[0, Preference[:account_number_digits]]
          variant = ProductNatureVariant.where('providers ->> ? = ?', 'panier_local', r.account_number).first
          unless variant
            computed_name = "Service - Vente en ligne - #{clean_account_number}"
            v_account = Account.find_or_create_by_number(clean_account_number)
            pnc = ProductNatureCategory.create_with(active: true, saleable: true, type: 'VariantCategories::ServiceCategory').find_or_create_by(product_account_id: v_account.id, name: computed_name)
            pn = ProductNature.create_with(active: true, variety: 'service', population_counting: 'decimal').find_or_create_by(name: computed_name)
            variant = pn.variants.create!(category_id: pnc.id,
                                          active: true,
                                          name: computed_name,
                                          providers: {'panier_local' => r.account_number},
                                          unit_name: 'unity'
                                          )
          end
          raise "No variant found for given #{r.account_number}" unless variant
          if r.sale_item_sens == 'D'
            pretax_amount = r.sale_item_amount * -1
          elsif r.sale_item_sens == 'C'
            pretax_amount = r.sale_item_amount
          end
          quantity = r.quantity
        end


        if sale && quantity && pretax_amount && variant && tax
          unless sale_item = SaleItem.where(
            sale_id: sale.id,
            quantity: quantity,
            pretax_amount: pretax_amount,
            variant_id: variant.id
          ).first
            sale.items.create!(
              amount: nil,
              pretax_amount: pretax_amount,
              unit_pretax_amount: nil,
              quantity: quantity,
              tax: tax,
              variant: variant,
              compute_from: :pretax_amount
            )
          end
          variant = nil
          quantity = nil
          pretax_amount = nil
        end
        w.check_point
      end

      # Restart counting
      added_sales = Sale.where(id: sale_ids)
      w.reset! added_sales.count, :yellow

      added_sales.each do |sale|
        sale.propose if sale.draft?
        sale.confirm
        sale.invoice(sale.invoiced_at)
        w.check_point
      end
    end
  end
end
