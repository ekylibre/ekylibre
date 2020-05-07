module PanierLocal
  class SalesExchanger < Base

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
    NORMALIZATION_CONFIG = [
      { col: 1, name: :invoiced_at, type: :date, constraint: :not_nil },
      { col: 3, name: :journal_nature, type: :string },
      { col: 4, name: :account_number, type: :string },
      { col: 5, name: :entity_name, type: :string, constraint: :not_nil },
      { col: 6, name: :entity_code, type: :string, constraint: :not_nil },
      { col: 7, name: :sale_reference_number, type: :string, constraint: :not_nil },
      { col: 8, name: :sale_description, type: :string },
      { col: 9, name: :sale_item_amount, type: :float, constraint: :greater_or_equal_to_zero },
      { col: 10, name: :sale_item_sens, type: :string },
      { col: 11, name: :sale_item_pretax_amount, type: :float },
      { col: 12, name: :vat_percentage, type: :float },
      { col: 13, name: :quantity, type: :integer },
    ]

    def check
      data, errors = open_and_decode_file(file)

      valid = errors.all?(&:empty?)

      fy_start = FinancialYear.at(data.first.invoiced_at)
      fy_stop = FinancialYear.at(data.last.invoiced_at)

      unless fy_start && fy_stop
        w.error 'Need a FinancialYear'
        valid = false
      end

      valid
    end

    def import
      # Opening and decoding
      rows = ActiveExchanger::CsvReader.new.read(file)
      # create or find sale_nature
      sale_nature = find_or_create_sale_nature

      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      data, _errors = parser.normalize(rows)

      sales_info = data.group_by { |d| d.sale_reference_number }

      sales_info.each { |_sale_reference_number, sale_info| create_sale(sale_info, sale_nature) }

    rescue Accountancy::AccountNumberNormalizer::NormalizationError => e
      raise StandardError.new("The account number length cant't be different from your own settings")
    end

    def create_sale(sale_info, sale_nature)
      # sale = Sale.where('providers ->> ? = ?', 'panier_local', sale_info.first.sale_reference_number).first
      sale = Sale.of_provider_name(:panier_local, :sales)
                 .find_by("provider -> 'data' ->> 'sale_reference_number' = ?", sale_info.first.sale_reference_number)

      if sale.nil?
        entity = get_or_create_entity(sale_info)
        client_sale_info = sale_info.select { |item| item.account_number.to_s.start_with?('411') }.first
        sale = Sale.new(
          invoiced_at: client_sale_info.invoiced_at,
          reference_number: client_sale_info.sale_reference_number,
          client: entity,
          nature: sale_nature,
          description: client_sale_info.sale_description,
          provider: { vendor: :panier_local, name: :sales, id: import_resource.id, data: { sale_reference_number: client_sale_info.sale_reference_number } }
        )

        tax = check_or_create_vat_account_and_amount(sale_info)

        product_account_lines = sale_info.select { |i| i.account_number.start_with?('7') }

        if product_account_lines.count > 1
          raise StandardError.new("This exchanger does not handle sales with more than one line with an account starting by '7' ")
        end

        product_account_line = product_account_lines.first
        if product_account_line.present?
          # Assuming we only have one variant ?
          variant = ProductNatureVariant.of_provider_name(:panier_local, :sales)
            .of_provider_data(:account_number, product_account_line.account_number)&.first

          if variant.blank?
            product_account = check_or_create_product_account(product_account_line)
            variant = create_variant(product_account, product_account_line)
          end
          pretax_amount = create_pretax_amount(product_account_line)

          #TODO: what is the real default quantity ?
          quantity = product_account_line.quantity || 1

          unless sale.items.find_by(
            sale_id: sale.id,
            quantity: quantity,
            pretax_amount: pretax_amount,
            variant_id: variant.id
          )
            sale.items.build(
              amount: nil,
              pretax_amount: pretax_amount,
              unit_pretax_amount: nil,
              quantity: quantity,
              tax: tax,
              variant: variant,
              compute_from: :pretax_amount
            )
          end
        end
      end

      sale.save!
    end

    def get_or_create_entity(sale_info)
      entity = Entity.where('codes ->> ? = ?', 'panier_local', sale_info.first.entity_code.to_s)
      if entity.any?
        entity.first
      else
        create_entity(sale_info)
      end
    end

    def create_entity_account(client_sale_info)
      client_number_account = client_sale_info.account_number.to_s
      acc = Account.find_or_initialize_by(number: client_number_account) #!
      attributes = {
        name: client_sale_info.entity_name,
        centralizing_account_name: 'clients',
        nature: 'auxiliary'
      }

      aux_number = client_number_account[3, client_number_account.length]

      if aux_number.match(/\A0*\z/).present?
        raise StandardError.new("Can't create account. Number provided can't be a radical class")
      else
        attributes[:auxiliary_number] = aux_number
      end
      acc.attributes = attributes

      acc
    end

    def create_entity(sale_info)
      client_sale_infos = sale_info.select { |item| item.account_number.to_s.start_with?('411') }

      if client_sale_infos.size == 1
        client_sale_info = client_sale_infos.first
        account = create_entity_account(client_sale_info)
        last_name = client_sale_info.entity_name.mb_chars.capitalize

        w.info "Create entity and link account"
        Entity.create!(
          nature: :organization,
          last_name: last_name,
          codes: { 'panier_local' => client_sale_info.entity_code },
          active: true,
          client: true,
          client_account_id: account.id
        )
      else
        raise StandardError.new("There should be only one line with an acccount starting with '411', Got #{client_sale_infos.size}")
      end
    end

    def check_or_create_vat_account_and_amount(sale_info)
      vat_account_infos = sale_info.select { |item| item.account_number.to_s.start_with?('445') }
      if vat_account_infos.size > 1
        raise StandardError.new("This exchanger does not handle sales with more than one line with an account starting by '445' ")
      end
      
      vat_account_info = vat_account_infos.first

      if vat_account_info.present?
        n = Accountancy::AccountNumberNormalizer.build
        clean_tax_account_number = n.normalize!(vat_account_info.account_number)

        tax_account = Account.find_by(number: clean_tax_account_number)
        tax = Tax.find_by(amount: vat_account_info.vat_percentage)

        if tax_account.blank? && tax.nil?
          tax = create_tax(vat_account_info, clean_tax_account_number)
        end
      end

      tax
    end

    def create_tax(vat_account_info, clean_tax_account_number)
      tax_account = Account.find_or_create_by_number(clean_tax_account_number)
      tax = Tax.find_by(amount: vat_account_info.vat_percentage, collect_account_id: tax_account.id)

      if tax.nil?
        tax = Tax.find_on(vat_account_info.invoiced_at.to_date, country: Preference[:country].to_sym, amount: vat_account_info.vat_percentage)
        tax.collect_account_id = tax_account.id
        tax.active = true
        tax.save!
      end

      tax
    end

    def check_or_create_product_account(product_account_line)
      n = Accountancy::AccountNumberNormalizer.build
      clean_account_number = n.normalize!(product_account_line.account_number)
      computed_name = "Service - Vente en ligne - #{clean_account_number}"

      Account.find_or_create_by_number(clean_account_number, name: computed_name)
    end

    def create_variant(product_account, product_account_line)
      n = Accountancy::AccountNumberNormalizer.build
      clean_account_number = n.normalize!(product_account_line.account_number)
      computed_name = "Service - Vente en ligne - #{clean_account_number}"

      pnc = ProductNatureCategory.create_with(name: computed_name, active: true, saleable: true, product_account_id: product_account.id, nature: :service, type: 'VariantCategories::ServiceCategory')
                                 .find_or_create_by(product_account_id: product_account.id, name: computed_name)

      pn = ProductNature.create_with(active: true, name: computed_name, variety: 'service', population_counting: 'decimal')
                        .find_or_create_by(name: computed_name)

      pn.variants.create!(
        active: true,
        name: computed_name,
        category: pnc,
        provider: { vendor: :panier_local, name: :sales, id: import_resource.id, data: { account_number: product_account_line.account_number } },
        unit_name: 'unity'
      )
    end

    def create_pretax_amount(product_account_line)
      if product_account_line.sale_item_sens == 'D'
        product_account_line.sale_item_amount * -1
      elsif product_account_line.sale_item_sens == 'C'
        product_account_line.sale_item_amount
      else
        raise StandardError.new("Can't create Sale item direction provided isn't a letter supported")
      end
    end

    def find_or_create_sale_nature
      sale_natures = SaleNature.of_provider_name(:panier_local, :sales)

      if sale_natures.empty?
        journal = find_or_create_journal
        catalog = find_or_create_catalog

        SaleNature.create_with(provider: { vendor: :panier_local, name: :sales, id: import_resource.id })
                  .find_or_create_by(name: I18n.t('exchanger.panier_local.sales.sale_nature_name'), catalog_id: catalog.id, currency: 'EUR', payment_delay: '30 days', journal_id: journal.id)
      elsif sale_natures.size == 1
        sale_natures.first
      else
        raise StandardError, "More than one sale_nature found, should not happen"
      end
    end

    def find_or_create_journal
      journals = Journal.of_provider_name(:panier_local, :sales)

      if journals.empty?
        Journal.create_with(provider: { vendor: :panier_local, name: :sales, id: import_resource.id })
               .find_or_create_by(code: 'PALO', nature: 'sales', name: 'Panier Local')
      elsif journals.size == 1
        journals.first
      else
        raise StandardError, "More than one journal found, should not happen"
      end
    end

    def find_or_create_catalog
      catalogs = Catalog.of_provider_name(:panier_local, :sales)

      if catalogs.empty?
        Catalog.create_with(provider: { vendor: :panier_local, name: :sales, id: import_resource.id })
               .find_or_create_by(code: 'PALO', currency: 'EUR', usage: 'sale', name: 'Panier Local')
      elsif catalogs.size == 1
        catalogs.first
      else
        raise StandardError, "More than one catalog found, should not happen"
      end
    end

    def open_and_decode_file(file)
      # Open and Decode: CSVReader::read(file)
      rows = ActiveExchanger::CsvReader.new.read(file)
      parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

      parser.normalize(rows)
    end

  end
end
