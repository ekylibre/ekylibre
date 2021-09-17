# frozen_string_literal: true

module Square
  class SalesExchanger < Base
    category :sales
    vendor :square

    # Imports sale_items into sales to make accountancy in CSV format
    # filename example : articles-2020-11-30-2021-01-13.csv
    # encoding UTF-16, separator tab
    NORMALIZATION_CONFIG = [
      { col: 0, name: :invoiced_on, type: :us_date, constraint: :not_nil },
      { col: 1, name: :invoiced_hour, type: :string, constraint: :not_nil },
      { col: 3, name: :category_name, type: :string },
      { col: 4, name: :article_name, type: :string },
      { col: 5, name: :quantity, type: :float, constraint: :not_nil },
      { col: 6, name: :price_level, type: :string },
      { col: 7, name: :ugs_number, type: :string },
      { col: 10, name: :sale_item_reduction_amount, type: :currency, constraint: :not_nil },
      { col: 11, name: :sale_item_pretax_amount, type: :currency, constraint: :not_nil },
      { col: 12, name: :sale_item_tax_amount, type: :currency, constraint: :not_nil },
      { col: 14, name: :transaction_number, type: :string, constraint: :not_nil },
      { col: 15, name: :payment_number, type: :string, constraint: :not_nil },
      { col: 16, name: :pos_equipment_name, type: :string },
      { col: 17, name: :notes, type: :string },
      { col: 18, name: :sale_url, type: :string },
      { col: 20, name: :pos_name, type: :string },
      { col: 22, name: :unity, type: :string },
      { col: 23, name: :round_quantity, type: :float }
    ].freeze

    def check
      data, errors = open_and_decode_file(file)

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end

      fy_start = FinancialYear.at(data.first.invoiced_on)
      fy_stop = FinancialYear.at(data.last.invoiced_on)

      if fy_start && fy_stop
        valid = true
      else
        w.error "No financial year exist between #{data.first.invoiced_on.l} and #{data.last.invoiced_on.l}"
        valid = false
      end

      w.count = data.size
      missing_variant = []
      data.each do |sale_line|
        variant_check = Maybe(find_variant_by_provider(sale_line.article_name))
                    .recover { find_variant_by_ugs(sale_line.ugs_number) }
                    .recover { find_variant_by_name(sale_line.article_name) }
        if variant_check.present?
          w.info "Variant exist on Ekylibre from Square"
          if variant_check.category.product_account_id?
            w.info "Product account exist"
          else
            w.error "Product account doesn't not exist on #{variant_check.name} with ID : #{variant_check.id}"
            valid = false
          end
        else
          missing_variant << sale_line.article_name
        end
        # check tax
        tax = find_tax_by_amounts(sale_line.sale_item_pretax_amount, sale_line.sale_item_tax_amount)
        if tax.present?
          w.info "Tax OK"
        else
          w.error "Tax doesn't match on #{sale_line.article_name}, pretax_amount : #{sale_line.sale_item_pretax_amount}, vat_amount : #{sale_line.sale_item_tax_amount}"
          valid = false
        end
        w.check_point
      end

      if missing_variant.any?
        w.error "No variant found for #{missing_variant.compact.uniq.to_sentence}"
        valid = false
      end
      valid
    end

    def import
      data, _errors = open_and_decode_file(file)

      sales_info = data.group_by(&:transaction_number)

      sale_nature = find_sale_nature_by_provider
      w.reset! sales_info.size, :yellow
      sales_info.each do |transaction_number, sale_info|
        find_or_create_sale(sale_info, sale_nature, reference_number: transaction_number)

        w.check_point
      end
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
      # entity is link_to pos_name
      entity = find_or_create_entity(sale_info.first.pos_name)
      # responsible is link_to pos_equipment_name
      if sale_info.first.pos_equipment_name.present?
        responsible = find_or_create_responsible_person(sale_info.first.pos_equipment_name)
      else
        responsible = find_or_create_responsible_person('Square default responsible')
      end

      description = "#{sale_info.first.sale_url} "
      description += "\n #{sale_info.first.notes}" if sale_info.first.notes.present?
      invoiced_at = to_invoiced_at(sale_info.first.invoiced_on, sale_info.first.invoiced_hour)

      sale = Sale.create!(
        client: entity,
        description:  description,
        invoiced_at: invoiced_at,
        reference_number: reference_number,
        nature: sale_nature,
        provider: provider_value(sale_reference_number: reference_number),
        responsible: responsible
      )

      sale_info.each do |sale_line|
        variant = Maybe(find_variant_by_provider(sale_line.article_name))
                    .recover { find_variant_by_ugs(sale_line.ugs_number) }
                    .recover { find_variant_by_name(sale_line.article_name) }
                    .or_raise("No variant found for #{sale_line.article_name}")

        tax = find_tax_by_amounts(sale_line.sale_item_pretax_amount, sale_line.sale_item_tax_amount)

        notes = "#{sale_line.category_name} | #{sale_line.article_name}"

        reduction_percentage = 0.0

        red = sale_line.sale_item_reduction_amount.to_d
        pretax = sale_line.sale_item_pretax_amount.to_d
        if red > 0.0 && pretax > 0.0
          reduction_percentage = (red / (pretax + red)).round(2)
        end

        item = sale.items.new(
          amount: sale_line.sale_item_pretax_amount.to_d + sale_line.sale_item_tax_amount.to_d,
          unit_pretax_amount: nil,
          pretax_amount: nil,
          reduction_percentage: reduction_percentage.abs * 100,
          quantity: sale_line.quantity&.to_d || 1,
          annotation: notes,
          tax: tax,
          variant: variant,
          compute_from: :amount
        )
        item.save!
      end
      sale.invoice(invoiced_at)
      Some(sale)
    end

    # @param [String] reference_number
    # @return [Sale, nil]
    def find_sale_by_provider(reference_number)
      unwrap_one('sale') { Sale.of_provider_name(self.class.vendor, provider_name).of_provider_data(:sale_reference_number, reference_number) }
    end

    # @return [Tax]
    # Formule : [Montant TTC] / (1 + ([Taux TVA] / 100))=[Montant HT]
    def find_tax_by_amounts(pretax_amount, tax_amount)
      tax_rate = (tax_amount.to_d / pretax_amount.to_d) * 100
      # hotfix because some product on Square are badly imputing taxe on 20 et 10 together
      tax_rate = 10.0 if tax_rate.between?(13, 16)
      tax_rate = 5.5 if tax_rate.between?(4, 6)
      unwrap_one('tax') do
        Tax.where(active: true, amount: ((tax_rate * 0.75)..(tax_rate * 1.25)))
      end
    end

    # @param [String] article_name
    # @return [ProductNatureVariant, nil]
    def find_variant_by_provider(article_name)
      unwrap_one('variant') do
        ProductNatureVariant.of_provider_name(self.class.vendor, provider_name)
                            .of_provider_data(:article_name, article_name)
      end
    end

    # @param [String] article_name
    # @return [ProductNatureVariant, nil]
    def find_variant_by_name(article_name)
      unaccent_article_name = I18n.transliterate(article_name)
      unwrap_one('variant') do
        ProductNatureVariant.where("replace(lower(name), ' ','') = ? OR replace(lower(name), ' ','') = ? OR replace(lower(work_number), ' ','') = ?", article_name.downcase.delete(' '), unaccent_article_name.downcase.delete(' '), article_name.downcase.delete(' '))
      end
    end

    # @param [String] article_name
    # @return [ProductNatureVariant, nil]
    def find_variant_by_ugs(ugs_number)
      return nil if ugs_number.blank?

      unaccent_ugs_number = I18n.transliterate(ugs_number)
      unwrap_one('variant') do
        ProductNatureVariant.where("work_number IS NOT NULL AND replace(lower(work_number), ' ','') = ?", unaccent_ugs_number.downcase.delete(' '))
      end
    end

    # @return [SaleNature, nil]
    def find_sale_nature_by_provider
      unwrap_one('sale nature') { SaleNature.of_provider_name(self.class.vendor, provider_name) }
    end

    protected

      def tl(*unit, **options)
        I18n.t("exchanger.square.sales.#{unit.map(&:to_s).join('.')}", **options)
      end

      def provider_name
        :sales
      end

    private

      def open_and_decode_file(file)
        # Open and Decode: CSVReader::read(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: "\t").read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end
  end
end
