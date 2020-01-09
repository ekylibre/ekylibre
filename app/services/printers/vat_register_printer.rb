# This object allow printing the general ledger
module Printers
  class VatRegisterPrinter < PrinterBase

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(started_on:, stopped_on:, state:)
        filters = [started_on, stopped_on]
        filters << state.join('-') if state
        filters.reject(&:blank?).join(' - ')
      end
    end

    def initialize(*_args, state:, period:, started_on:, stopped_on:, template:, **_options)
      super(template: template)
      @state = state
      @period = period
      @started_on = started_on
      @stopped_on = stopped_on
    end

    def key
      self.class.build_key(started_on: @started_on, stopped_on: @stopped_on, state: @state)
    end

    def document_name
      "#{@template.nature.human_name} (#{humanized_period})"
    end

    def humanized_period
      return :on_all_exercises.tl if @period == 'all'
      financial_year = FinancialYear.find_by(started_on: Date.parse(@started_on), stopped_on: Date.parse(@stopped_on))
      return financial_year.code if financial_year
      I18n.translate('labels.from_to_date', from: Date.parse(@started_on).l, to: Date.parse(@stopped_on).l)
    end

    def compute_dataset
      vat_dataset = []

      taxe_declarations = if @state&.any?
                            TaxDeclaration.where(state: @state).where('started_on >= ? AND stopped_on <= ?', @started_on, @stopped_on)
                          else
                            TaxDeclaration.where('started_on >= ? AND stopped_on <= ?', @started_on, @stopped_on)
                          end

      taxe_declarations.each do |td|
        td.items.includes(parts: { journal_entry_item: :entry }).each do |i|
          i.parts.each do |p|
            jei = p.journal_entry_item
            e = jei.entry
            item = HashWithIndifferentAccess.new
            item[:entry_id] = e.id
            item[:entry_number] = e.number
            item[:entry_printed_on] = e.printed_on.l
            item[:entry_month_name] = I18n.l(Date::MONTHNAMES[e.printed_on.month])
            item[:entry_item_account_number] = jei.account.number
            item[:entry_item_account_name] = jei.account.name
            item[:entry_item_name] = jei.name
            item[:entry_item_debit] = jei.debit.to_f
            item[:entry_item_credit] = jei.credit.to_f
            item[:tax_amount] = p.tax_amount.to_f
            item[:pretax_amount] = p.pretax_amount.to_f
            item[:tax_name] = jei.tax.name
            item[:tax_account] = jei.vat_item_to_product_account
            vat_dataset << item
          end
        end
      end

      data_filters = []
      if @state&.any?
        content = []
        content << :draft.tl if @state.include?('draft')
        content << :confirmed.tl if @state.include?('validated')
        content << :sent.tl if @state.include?('sent')
        data_filters << :tax_declarations_states.tl + ' : ' + content.to_sentence
      end

      vat_dataset << data_filters
      vat_dataset.compact
    end

    def run_pdf
      dataset = compute_dataset
      data_filters = dataset.pop

      generate_report(@template_path) do |r|

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
        r.add_field 'PERIOD', humanized_period
        r.add_field 'DATE', Date.today.l
        r.add_field 'STARTED_ON', @started_on.to_date.l
        r.add_field 'STOPPED_ON', @stopped_on.to_date.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '

        r.add_table('Tableau1', dataset, header: true) do |t|
          t.add_column(:entry_id) { |item| item[:entry_id] }
          t.add_column(:entry_number) { |item| item[:entry_number] }
          t.add_column(:entry_printed_on) { |item| item[:entry_printed_on] }
          t.add_column(:entry_item_account_number) { |item| item[:entry_item_account_number] }
          t.add_column(:entry_item_account_name) { |item| item[:entry_item_account_name] }
          t.add_column(:entry_item_name) { |item| item[:entry_item_name] }
          t.add_column(:entry_item_debit) { |item| item[:entry_item_debit] }
          t.add_column(:entry_item_credit) { |item| item[:entry_item_credit] }
          t.add_column(:tax_amount) { |item| item[:tax_amount] }
          t.add_column(:pretax_amount) { |item| item[:pretax_amount] }
          t.add_column(:tax_account) { |item| item[:tax_account] }
        end
      end
    end

    def run_csv(csv)
      dataset = compute_dataset[0...-1]

      csv << [
        JournalEntry.human_attribute_name(:id),
        JournalEntry.human_attribute_name(:number),
        JournalEntry.human_attribute_name(:printed_on),
        JournalEntry.human_attribute_name(:printed_on),
        Account.human_attribute_name(:number),
        Account.human_attribute_name(:name),
        JournalEntryItem.human_attribute_name(:name),
        JournalEntryItem.human_attribute_name(:debit),
        JournalEntryItem.human_attribute_name(:credit),
        TaxDeclarationItemPart.human_attribute_name(:tax_amount),
        TaxDeclarationItemPart.human_attribute_name(:pretax_amount),
        Tax.human_attribute_name(:name),
        Account.human_attribute_name(:label),
      ]

      dataset.each do |item|
          csv << [
            item[:entry_id],
            item[:entry_number],
            item[:entry_printed_on],
            item[:entry_month_name],
            item[:entry_item_account_number],
            item[:entry_item_account_name],
            item[:entry_item_name],
            item[:entry_item_debit],
            item[:entry_item_credit],
            item[:tax_amount],
            item[:pretax_amount],
            item[:tax_name],
            item[:tax_account]
          ]
      end
    end
  end
end
