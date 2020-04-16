module Printers
  class JournalLedgerPrinter < PrinterBase

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(started_on:, stopped_on:, states:, journal:)
        states = deprecated_filter(states, :states)

        filters = [journal.name, started_on, stopped_on]
        filters << states.sort.join('-') if states
        filters.reject(&:blank?).join(' - ')
      end
    end

    def initialize(*_args, journal:, states:, period:, started_on:, stopped_on:, template:, **_options)
      super(template: template)
      states = self.class.deprecated_filter(states, :states)

      @journal = journal
      @states = states
      @period = period
      @started_on = started_on
      @stopped_on = stopped_on
    end

    def key
      self.class.build_key(started_on: @started_on, stopped_on: @stopped_on, states: @states, journal: @journal)
    end

    def document_name
      "#{@template.nature.human_name} (#{@journal.name}, #{humanized_period})"
    end

    def humanized_period
      return :on_all_exercises.tl if @period == 'all'
      financial_year = FinancialYear.find_by(started_on: Date.parse(@started_on), stopped_on: Date.parse(@stopped_on))
      return financial_year.code if financial_year
      I18n.translate('labels.from_to_date', from: Date.parse(@started_on).l, to: Date.parse(@stopped_on).l)
    end

    def compute_dataset
      ledger = []

      if @states&.any?
        a = @states.map { |state| "'#{state}'" }.join(', ')
        states_array = "state IN (#{a})"
      else
        states_array = '1=1'
      end

      selected_journal_id = @journal.id || 0
      if selected_journal_id > 0
        select_journal = "journal_id = #{selected_journal_id}"
      else
        select_journal = "1=1"
      end

      total_debit = 0.0
      total_credit = 0.0
      entry_count = 0

      je = JournalEntry.between(@started_on, @stopped_on)
             .where(select_journal)
             .where(states_array)
             .order('journal_entries.printed_on ASC, journal_entries.number ASC')

      je.group_by { |e| [e.printed_on.month, e.printed_on.year] }.each do |((month_number, year), entries)|
        month = HashWithIndifferentAccess.new
        month[:name] = I18n.t('date.month_names')[month_number].capitalize + '/' + year.to_s
        month[:items] = []
        month_total_debit = 0.0
        month_total_credit = 0.0
        month_entry_count = entries.count
        entries.each do |e|
          item = HashWithIndifferentAccess.new
          item[:entry_number] = e.number
          item[:printed_on] = e.printed_on.strftime('%d/%m/%Y')
          item[:journal_name] = e.journal.name.to_s
          item[:continuous_number] = e.continuous_number.to_s if e.continuous_number
          item[:reference_number] = e.reference_number.to_s
          item[:label] = e.items.first.displayed_label_in_accountancy.to_s
          item[:state] = e.state_label
          item[:real_debit] = e.real_debit
          item[:real_credit] = e.real_credit
          item[:balance] = e.balance
          item[:entry_items] = []
          e.items.each do |i|
            entry_item = HashWithIndifferentAccess.new
            entry_item[:account_number] = i.account.number.to_s
            entry_item[:account_name] = i.account.name.to_s
            entry_item[:real_debit] = i.real_debit
            entry_item[:real_credit] = i.real_credit
            item[:entry_items] << entry_item
          end
          month_total_debit += e.real_debit
          month_total_credit += e.real_credit
          month[:items] << item
          total_debit += e.real_debit
          total_credit += e.real_credit
          entry_count += 1
        end
        month[:total_debit] = month_total_debit
        month[:total_credit] = month_total_credit
        month[:balance] = month_total_debit - month_total_credit
        month[:entry_count] = month_entry_count

        ledger << month

      end

      total_balance = total_debit - total_credit

      ledger << { entry_count: entry_count, total_credit: total_credit, total_debit: total_debit, total_balance: total_balance }

      data_filters = []

      if @states&.any?
        content = []
        content << :draft.tl if @states.include?('draft')
        content << :confirmed.tl if @states.include?('confirmed')
        content << :closed.tl if @states.include?('closed')
        data_filters << :journal_entries_states.tl + ' : ' + content.to_sentence
      end

      ledger << data_filters
      ledger.compact
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
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '


        r.add_section('Section2', dataset[0...-1]) do |sm|

          sm.add_field(:month_name) { |month| month[:name] }

          sm.add_section('Section3', "items") do |s|
              s.add_field(:entry_number) { |item| item[:entry_number] }
              s.add_field(:printed_on) { |item| item[:printed_on] }
              s.add_field(:journal_name) { |item| item[:journal_name] }
              s.add_field(:reference_number) { |item| item[:reference_number] }
              s.add_field(:label) { |item| item[:label] }
              s.add_field(:continuous_number) { |item| item[:continuous_number] }

              s.add_table('Tableau7', "entry_items") do |t|
                t.add_column(:item_account_number) { |entry_item| entry_item[:account_number] }
                t.add_column(:item_account_name) { |entry_item| entry_item[:account_name] }
                t.add_column(:item_real_debit) { |entry_item| entry_item[:real_debit] }
                t.add_column(:item_real_credit) { |entry_item| entry_item[:real_credit] }
              end

              s.add_field(:state) { |item| item[:state] }
              s.add_field(:real_debit) { |item| item[:real_debit] }
              s.add_field(:real_credit) { |item| item[:real_credit] }
              s.add_field(:balance) { |item| item[:balance] }
          end

          sm.add_field(:month_total_debit) { |month| month[:total_debit] }
          sm.add_field(:month_total_credit) { |month| month[:total_credit] }
          sm.add_field(:month_balance) { |month| month[:balance] }
          sm.add_field(:month_entry_count) { |month| month[:entry_count] }

        end

        r.add_field :entry_count, dataset.last[:entry_count]
        r.add_field :total_credit, dataset.last[:total_credit]
        r.add_field :total_debit, dataset.last[:total_debit]
        r.add_field :total_balance, dataset.last[:total_balance]
      end
    end
  end
end
