# frozen_string_literal: true

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
      { col: 10, name: :sale_item_direction, type: :string },
      { col: 11, name: :sale_item_pretax_amount, type: :float },
      { col: 12, name: :vat_percentage, type: :float },
      { col: 13, name: :quantity, type: :integer },
    ]

    def check
      data, errors = open_and_decode_file(file)

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end

      fy_start = FinancialYear.at(data.first.invoiced_at)
      fy_stop = FinancialYear.at(data.last.invoiced_at)

      unless fy_start && fy_stop
        w.error 'Need a FinancialYear'
        valid = false
      end

      if responsible_person.nil?
        w.error "A responsible is needed to execute this import"
        valid = false
      end

      valid
    end

    # @return [Entity, nil]
    def responsible_person
      responsible&.person
    end

    def import
      data, _errors = open_and_decode_file(file)

      sales_info = data.group_by { |d| d.sale_reference_number }

      sale_nature = find_or_create_sale_nature
      w.count = sales_info.size
      sales_info.each do |sale_reference_number, sale_info|
        find_or_create_sale(sale_info, sale_nature, reference_number: sale_reference_number)

        w.check_point
      end
    rescue Accountancy::AccountNumberNormalizer::NormalizationError => e
      raise StandardError, "The account number length cant't be different from your own settings"
    end

    # @param [Array<OpenStruct>] sale_info
    # @param [SaleNature] sale_nature
    # @param [String] reference_number
    # @return [Maybe<Sale>]
    def find_or_create_sale(sale_info, sale_nature, reference_number:)
      Maybe(find_sale_by_provider(reference_number))
        .recover { create_sale(sale_info, sale_nature, reference_number: reference_number) }
    end

    # @param [Array<OpenStruct>] sale_info
    # @param [SaleNature] sale_nature
    # @param [String] reference_number
    # @return [Maybe<Sale>]
    def create_sale(sale_info, sale_nature, reference_number:)
      if sale_info.size == 1 && sale_info.first.sale_item_amount.zero? && sale_info.first.account_number.start_with?(client_account_radix)
        None()
      else
        grouped_lines = sale_info.group_by do |line|
          account_number = line.account_number

          if account_number.start_with?(client_account_radix)
            :client
          elsif account_number.start_with?('445')
            :tax
          elsif account_number.start_with?('7')
            :product
          else
            :unknown
          end
        end

        unknown_lines = grouped_lines.fetch(:unknown, [])
        if unknown_lines.any?
          raise StandardError, "Found #{unknown_lines.size} unknown lines for sale #{reference_number}"
        end

        client_info = unwrap_one("client info", exact: true) { grouped_lines.fetch(:client, []) }
        tax_info = unwrap_one(
          "tax info",
          exact: true,
          error_none: -> { tl(:errors, :sale_data_missing_tax_information, reference_number: reference_number) }
        ) { grouped_lines.fetch(:tax, []) }
        product_infos = grouped_lines.fetch(:product, [])

        entity = find_or_create_entity(client_info.entity_name, client_info.account_number, client_info.entity_code)
        tax = find_or_create_tax(tax_info)

        sale = Sale.new(
          client: entity,
          description: client_info.sale_description,
          invoiced_at: client_info.invoiced_at,
          nature: sale_nature,
          provider: provider_value(sale_reference_number: reference_number),
          reference_number: reference_number,
          responsible: responsible_person
        )

        product_infos.each do |product_line|
          variant = Maybe(find_variant_by_provider(product_line.account_number))
                      .recover { create_variant_with_account(product_line.account_number) }
                      .or_raise

          sale.items.build(
            amount: nil,
            pretax_amount: create_pretax_amount(product_line),
            unit_pretax_amount: nil,
            quantity: product_line.quantity || 1,
            tax: tax,
            variant: variant,
            compute_from: :pretax_amount
          )
        end

        sale.save!

        Some(sale)
      end
    end

    # @param [String] reference_number
    # @return [Sale, nil]
    def find_sale_by_provider(reference_number)
      unwrap_one('sale') { Sale.of_provider_name(:panier_local, :sales).of_provider_data(:sale_reference_number, reference_number) }
    end

    # @param [OpenStruct] tax_info
    # @return [Tax]
    def find_or_create_tax(tax_info)
      Maybe(find_tax_by_provider(tax_info.vat_percentage, tax_info.account_number))
        .recover { find_or_create_tax_by_account(tax_info) }
        .or_raise
    end

    # @param [Float] vat_percentage
    # @param [String] account_number
    # @return [Tax, nil]
    def find_tax_by_provider(vat_percentage, account_number)
      unwrap_one('tax') do
        Tax.of_provider_name(:panier_local, :sales)
           .of_provider_data(:account_number, account_number)
           .of_provider_data(:vat_percentage, vat_percentage.to_s)
      end
    end

    # @param [OpenStruct] tax_info
    # @return [Tax]
    def find_or_create_tax_by_account(tax_info)
      clean_tax_account_number = account_normalizer.normalize!(tax_info.account_number)

      tax_account = Maybe(find_account_by_provider(tax_info.account_number))
                      .recover { Account.find_or_create_by_number(
                        clean_tax_account_number,
                        provider: provider_value(account_number: tax_info.account_number)
                      ) }
                      .or_raise

      Maybe(Tax.find_by(amount: tax_info.vat_percentage, collect_account_id: tax_account.id))
        .recover { create_tax(tax_info, tax_account) }
        .or_raise
    end

    # @param [OpenStruct] tax_info
    # @param [Account] tax_account
    # @return [Tax]
    def create_tax(tax_info, tax_account)
      # Import from nomenclature!
      # BUG collect account is created and dropped if it doesn't match with the one from PALO
      tax = Tax.find_on(tax_info.invoiced_at.to_date, country: Preference[:country].to_sym, amount: tax_info.vat_percentage)
      if tax.nil?
        raise StandardError, "Unable to create tax"
      end

      tax.provider = provider_value(account_number: tax_info.account_number, vat_percentage: tax_info.vat_percentage)
      tax.collect_account_id = tax_account.id
      tax.active = true
      tax.save!

      tax
    end

    # @param [String] account_number
    # @return [ProductNatureVariant, nil]
    def find_variant_by_provider(account_number)
      unwrap_one('variant') do
        ProductNatureVariant.of_provider_name(:panier_local, :sales)
                            .of_provider_data(:account_number, account_number)
      end
    end

    # @param [String] account_number
    # @return [ProductNatureVariant]
    def create_variant_with_account(account_number)
      product_account = find_or_create_product_account(account_number)

      create_variant(product_account, account_number)
    end

    # @param [String] account_number
    # @return [Account]
    def find_or_create_product_account(account_number)
      clean_account_number = account_normalizer.normalize!(account_number)

      Maybe(find_account_by_provider(account_number))
        .recover {
          Account.find_or_create_by_number(
            clean_account_number,
            name: "Service - Vente en ligne - #{clean_account_number}",
            provider: provider_value(account_number: account_number)
          )
        }
        .or_raise
    end

    # @param [Account] account
    # @param [String] account_number
    # @return [ProductNatureVariant]
    def create_variant(account, account_number)
      computed_name = "Service - Vente en ligne - #{account.number}"

      pnc = ProductNatureCategory.create_with(active: true, saleable: true, nature: :service, type: 'VariantCategories::ServiceCategory')
                                 .find_or_create_by(product_account_id: account.id, name: computed_name)

      pn = ProductNature.create_with(active: true, variety: 'service', population_counting: 'decimal')
                        .find_or_create_by(name: computed_name)

      pn.variants.create!(
        active: true,
        name: computed_name,
        category: pnc,
        provider: provider_value(account_number: account_number),
        unit_name: 'unity'
      )
    end

    # @param [OpenStruct] product_line
    # @return [Float]
    def create_pretax_amount(product_line)
      if product_line.sale_item_direction == 'D'
        product_line.sale_item_amount * -1
      elsif product_line.sale_item_direction == 'C'
        product_line.sale_item_amount
      else
        raise StandardError.new("Can't create Sale item direction provided isn't a letter supported")
      end
    end

    # @return [SaleNature]
    def find_or_create_sale_nature
      name = I18n.t('exchanger.panier_local.sales.sale_nature_name')

      Maybe(find_sale_nature_by_provider)
        .recover { SaleNature.find_by(name: name) }
        .recover { create_sale_nature(name) }
        .or_raise
    end

    # @return [SaleNature, nil]
    def find_sale_nature_by_provider
      unwrap_one('sale nature') { SaleNature.of_provider_name(:panier_local, :sales) }
    end

    # @param [String] name
    # @return [SaleNature]
    def create_sale_nature(name)
      journal = find_or_create_journal
      catalog = find_or_create_catalog

      SaleNature.create!(
        catalog_id: catalog.id,
        currency: 'EUR',
        journal_id: journal.id,
        name: name,
        payment_delay: '30 days',
        provider: { vendor: :panier_local, name: :sales, id: import_resource.id }
      )
    end

    # @return [Journal]
    def find_or_create_journal
      Maybe(find_journal_by_provider)
        .recover { Journal.create_with(provider: { vendor: :panier_local, name: :sales, id: import_resource.id })
                          .find_or_create_by(code: 'PALO', nature: 'sales', name: 'Panier Local') }
        .or_raise
    end

    # @return [Journal, nil]
    def find_journal_by_provider
      unwrap_one('journal') { Journal.of_provider_name(:panier_local, :sales) }
    end

    # @return [Catalog]
    def find_or_create_catalog
      Maybe(find_catalog_by_provider)
        .recover { Catalog.create_with(provider: { vendor: :panier_local, name: :sales, id: import_resource.id })
                          .find_or_create_by(code: 'PALO', currency: 'EUR', usage: 'sale', name: 'Panier Local') }
        .or_raise
    end

    # @return [Catalog, nil]
    def find_catalog_by_provider
      unwrap_one('catalog') { Catalog.of_provider_name(:panier_local, :sales) }
    end

    protected

      def tl(*unit, **options)
        I18n.t("exchanger.panier_local.sales.#{unit.map(&:to_s).join('.')}", **options)
      end

      def provider_name
        :sales
      end

    private

      def open_and_decode_file(file)
        # Open and Decode: CSVReader::read(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: ';').read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end
  end
end
