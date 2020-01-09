# This object allow printing the general ledger
module Printers
  class PendingVatRegisterPrinter < PrinterBase

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(tax_declaration:)
        "#{tax_declaration.number} - #{tax_declaration.state}"
      end
    end

    def initialize(*_args, tax_declaration:,template:, **_options)
      super(template: template)
      @tax_declaration = tax_declaration
    end

    def key
      self.class.build_key(tax_declaration: @tax_declaration)
    end

    def document_name
      "#{I18n.translate("labels.#{@tax_declaration.state}_vat_declaration")} (#{humanized_period})"
    end

    def humanized_period
      from, to = [@tax_declaration.started_on, @tax_declaration.stopped_on]
      financial_year = FinancialYear.find_by(started_on: from, stopped_on: to)
      return financial_year.code if financial_year
      I18n.translate('labels.from_to_date', from: from.l, to: to.l)
    end

    def compute_dataset
      vat_dataset = []

      taxes = Tax.where(id: @tax_declaration.items.pluck(:tax_id), intracommunity: false).where.not(nature: :eu_vat).reorder(amount: :desc)
      columns = [:collected, :deductible, :fixed_asset_deductible]

      columns.each do |c|
        cat = HashWithIndifferentAccess.new
        cat[:name] = TaxDeclarationItem.human_attribute_name(c)
        cat[:items] = []

        taxes.each do |t|
          cat_tax = HashWithIndifferentAccess.new
          cat_tax[:name] = t.name
          cat_tax[:parts] = []
          tax_total_tax = 0.0
          tax_total_pretax = 0.0

          @tax_declaration.items.where(tax_id: t.id).includes(parts: { journal_entry_item: :entry }).each do |i|

            i.parts.where(direction: c).each do |p|
              jei = p.journal_entry_item
              e = jei.entry
              item = HashWithIndifferentAccess.new
              item[:entry_number] = e.number
              item[:entry_printed_on] = e.printed_on.l
              item[:item_account] = jei.vat_item_to_product_account
              item[:entry_item_name] = jei.name
              item[:tax_amount] = p.tax_amount.to_f
              item[:pretax_amount] = p.pretax_amount.to_f
              item[:amount] = (p.pretax_amount.to_f + p.tax_amount.to_f).round(2)
              cat_tax[:parts] << item
            end

            tax_total_tax += i.send("#{c}_tax_amount")
            tax_total_pretax += i.send("#{c}_pretax_amount")
          end

          cat_tax[:pretax_amount] = tax_total_pretax
          cat_tax[:tax_amount] = tax_total_tax
          cat_tax[:amount] = tax_total_tax + tax_total_pretax
          cat[:items] << cat_tax
        end

        cat[:pretax_amount] = cat[:items].map { |i| i[:pretax_amount] }.sum
        cat[:tax_amount] = cat[:items].map { |i| i[:tax_amount] }.sum
        cat[:amount] = cat[:pretax_amount] + cat[:tax_amount]
        vat_dataset << cat
      end

      tax_amounts = vat_dataset.map { |d| d[:tax_amount] }
      to_pay = tax_amounts.first - tax_amounts[1..-1].sum

      if to_pay >= 0.0
        vat_label = :to_pay.tl
        vat_balance = to_pay
      else
        vat_label = :to_reclaim.tl
        vat_balance = -to_pay
      end

      vat_dataset << vat_label
      vat_dataset << vat_balance


      intra_taxes = Tax.where(id: @tax_declaration.items.pluck(:tax_id), intracommunity: true, nature: :eu_vat).reorder(amount: :desc)
      # intra_columns = [:collected, :intracommunity_payable, :deductible, :fixed_asset_deductible]
      intra_columns = [:collected, :deductible]
      intra_column_labels = { collected: :sales.tl, deductible: :purchases.tl }

      intra_columns.each do |c|
        intra_cat = HashWithIndifferentAccess.new
        intra_cat[:name] = intra_column_labels[c]
        intra_cat[:items] = []

        intra_taxes.each do |t|
          intra_cat_tax = HashWithIndifferentAccess.new
          intra_cat_tax[:name] = t.name
          intra_cat_tax[:parts] = []
          intra_tax_total_tax = 0.0
          intra_tax_total_pretax = 0.0

          @tax_declaration.items.where(tax_id: t.id).includes(parts: { journal_entry_item: :entry }).each do |i|
            i.parts.where(direction: c).each do |p|
              next if c == :collected && p.tax_amount > 0
              jei = p.journal_entry_item
              e = jei.entry
              intra_item = HashWithIndifferentAccess.new
              intra_item[:entry_number] = e.number
              intra_item[:entry_printed_on] = e.printed_on.l
              intra_item[:item_account] = jei.vat_item_to_product_account
              intra_item[:entry_item_name] = jei.name
              intra_item[:tax_amount] = p.tax_amount.to_f
              intra_item[:pretax_amount] = p.pretax_amount.to_f
              intra_item[:amount] = intra_item[:pretax_amount]
              intra_cat_tax[:parts] << intra_item
            end

            intra_tax_total_tax = i.send("#{c}_tax_amount")
            intra_tax_total_pretax += i.send("#{c}_pretax_amount")
          end

          intra_cat_tax[:pretax_amount] = intra_cat_tax[:parts].map { |p| p[:pretax_amount] }.sum.to_d
          intra_cat_tax[:tax_amount] = intra_cat_tax[:parts].map { |p| p[:tax_amount] }.sum.to_d
          intra_cat_tax[:amount] = intra_tax_total_pretax
          intra_cat[:items] << intra_cat_tax
        end

        intra_cat[:pretax_amount] = intra_cat[:items].map { |i| i[:pretax_amount] }.sum.to_d
        intra_cat[:tax_amount] = intra_cat[:items].map { |i| i[:tax_amount] }.sum.to_d
        intra_cat[:amount] = intra_cat[:pretax_amount]
        vat_dataset << intra_cat
      end

      vat_dataset.compact
    end

    def run_pdf
      dataset = compute_dataset

      generate_report(@template_path) do |r|
        # build header
        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        # build started and stopped
        started_on = @tax_declaration.started_on
        stopped_on = @tax_declaration.stopped_on
        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
        r.add_field 'PERIOD', humanized_period
        r.add_field 'DATE', Date.today.l
        r.add_field 'STARTED_ON', started_on.to_date.l
        r.add_field 'STOPPED_ON', stopped_on.to_date.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'VAT_BALANCE', dataset[3]
        r.add_field 'VAT_BALANCE_AMOUNT', dataset[4]

        r.add_section('Section1', dataset[0...3]) do |first_section|
          first_section.add_field(:vat_header) { |item| item[:name] }
          first_section.add_field(:general_pretax_amount) { |item| item[:pretax_amount] }
          first_section.add_field(:general_tax_amount) { |item| item[:tax_amount] }
          first_section.add_field(:general_amount) { |item| item[:amount] }

          first_section.add_section('Section2', :items) do |second_section|
            second_section.add_field(:vat_rate) { |item| item[:name] }
            second_section.add_field(:total_pretax_amount) { |item| item[:pretax_amount] }
            second_section.add_field(:total_tax_amount) { |item| item[:tax_amount] }
            second_section.add_field(:total_amount) { |item| item[:amount] }

            second_section.add_table('Table6', :parts, header: false) do |first_table|
              first_table.add_column(:printed_on) { |part| part[:entry_printed_on] }
              first_table.add_column(:label) { |part| part[:entry_item_name] }
              first_table.add_column(:pretax_amount) { |part| part[:pretax_amount] }
              first_table.add_column(:tax_amount) { |part| part[:tax_amount] }
              first_table.add_column(:amount) { |part| part[:amount] }
            end
          end
        end

        r.add_section('Section3', dataset[-2..-1]) do |first_section|
          first_section.add_field(:vat_header) { |item| item[:name] }
          first_section.add_field(:general_pretax_amount) { |item| item[:pretax_amount] }
          first_section.add_field(:general_tax_amount) { |item| item[:tax_amount] }
          first_section.add_field(:general_amount) { |item| item[:amount] }

          first_section.add_section('Section4', :items) do |second_section|
            second_section.add_field(:vat_rate) { |item| item[:name] }
            second_section.add_field(:total_pretax_amount) { |item| item[:pretax_amount] }
            second_section.add_field(:total_tax_amount) { |item| item[:tax_amount] }
            second_section.add_field(:total_amount) { |item| item[:amount] }

            second_section.add_table('Table12', :parts, header: false) do |first_table|
              first_table.add_column(:printed_on) { |part| part[:entry_printed_on] }
              first_table.add_column(:label) { |part| part[:entry_item_name] }
              first_table.add_column(:pretax_amount) { |part| part[:pretax_amount] }
              first_table.add_column(:tax_amount) { |part| part[:tax_amount] }
            end
          end
        end
      end
    end

    def run_csv(csv)
      dataset = compute_dataset

      csv << [
        "#{:date.tl} - #{:description.tl}",
        :pretax_amount.tl,
        :tax_amount.tl
      ]

      csv << [:standard_vat.tl]

      dataset[0...3].each do |tax_nature|
        csv << [
          "#{:vat.tl} #{tax_nature[:name]}"
        ]

        tax_nature[:items].each do |tax|

          tax[:parts].each do |part|
            csv << [
              "#{part[:entry_printed_on]} #{part[:entry_item_name]}",
              part[:pretax_amount],
              part[:tax_amount]
            ]
          end

          csv << [
            "#{:total.tl} #{tax[:name]}",
            tax[:pretax_amount],
            tax[:tax_amount]
          ]
        end

        csv << [
          "#{:general_total.tl} #{:vat.tl} #{tax_nature[:name]}",
          tax_nature[:pretax_amount],
          tax_nature[:tax_amount]
        ]
      end

      csv << [
        "#{:vat.tl} #{dataset[3]}",
        "",
        dataset[4]
      ]

      csv << [:intracommunautary_vat.tl]

      dataset[-2..-1].each do |tax_nature|
        csv << [
          "#{:vat.tl} #{tax_nature[:name]}"
        ]

        tax_nature[:items].each do |tax|

          tax[:parts].each do |part|
            csv << [
              "#{part[:entry_printed_on]} #{part[:entry_item_name]}",
              part[:pretax_amount]
            ]
          end

          csv << [
            "#{:total.tl} #{tax[:name]}",
            tax[:pretax_amount]
          ]
        end

        csv << [
          "#{:general_total.tl} #{:vat.tl} #{tax_nature[:name]}",
          tax_nature[:pretax_amount]
        ]
      end
    end
  end
end
