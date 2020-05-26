module Printers
  class AccountJournalEntrySheetPrinter < PrinterBase
    # for accessing to number_to_accountancy
    include ApplicationHelper

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(period:, states:, account:)
        filters = [account.label.strip, period]
        filters.reject(&:blank?).join(' - ')
      end
    end

    def initialize(account:, states:, lettering_state:, period:, started_on:, stopped_on:, template:)
      super(template: template)
      states = self.class.deprecated_filter(states, :states)

      @account = account
      @states = states
      @period = period
      @lettering_state = lettering_state

      # build dates conditions from period options
      if @period == 'all'
        @started_on = FinancialYear.first_of_all.started_on.to_s
        @stopped_on = FinancialYear.current.stopped_on.to_s
      elsif @period == 'interval'
        @started_on = started_on
        @stopped_on = stopped_on
      else # period=2019-01-01_2019-12-31
        @started_on = period.split('_').first
        @stopped_on = period.split('_').last
      end

    end

    def key
      self.class.build_key(period: @period, states: @states, account: @account)
    end

    def document_name
      "#{@template.nature.human_name} | #{@account.label.strip} (#{humanized_period})"
    end

    def humanized_period
      I18n.translate('labels.from_to_date', from: Date.parse(@started_on).l, to: Date.parse(@stopped_on).l)
    end

    def compute_dataset

      h = {}
      h[:items] = []

      # build conditions for @states
      if @states&.any?
        a = @states.map { |state| "'#{state}'" }.join(', ')
        states_array = "journal_entry_items.state IN (#{a})"
      else
        states_array = '1=1'
      end

      # build conditions @lettering_state ["lettered", "partially_lettered", "unlettered"]
      l_conditions = []
      lettered_content = []
      if @lettering_state != nil
        @lettering_state.each do |letter_state|
          case letter_state
          when "lettered"
            condition = "(letter IS NOT NULL AND letter NOT ILIKE '%*')"
            lettered_content << :lettered.tl
          when "partially_lettered"
            condition = "(letter IS NOT NULL AND letter ILIKE '%*')"
            lettered_content << :partially_lettered.tl
          when "unlettered"
            condition = "(letter IS NULL)"
            lettered_content << :unlettered.tl
          else
            condition = '(1=1)'
          end
          l_conditions << condition
        end
        letter_condition = l_conditions.join(' OR ')
      else
        letter_condition = '1=1'
        lettered_content << :lettered.tl
        lettered_content << :partially_lettered.tl
        lettered_content << :unlettered.tl
      end

      items_dataset = @account.journal_entry_items
                      .between(@started_on, @stopped_on)
                      .includes(entry: [:sales, :purchases])
                      .where(states_array)
                      .where(letter_condition)
                      .reorder('journal_entry_items.printed_on ASC, journal_entry_items.entry_number ASC')

      h[:items] = items_dataset.map do |item|
        {
        name: item.name,
        printed_on: item.printed_on.l(format: '%d/%m/%Y'),
        journal_entry_items_number: item.entry_number,
        journal_entry_reference_number: item.entry.reference_number,
        letter: item.letter,
        real_debit: item.real_debit,
        real_credit: item.real_credit
      }.with_indifferent_access
      end

      h[:total_items] = []
      total_debit = items_dataset.sum(:real_debit)
      total_credit = items_dataset.sum(:real_credit)
      total_balance = items_dataset.sum(:balance)
      h[:total_items] << {total_debit: total_debit, total_credit: total_credit, total_balance: total_balance}

      h[:data_filters] = []

      if @states&.any?
        content = []
        content << :draft.tl if @states.include?('draft')
        content << :confirmed.tl if @states.include?('confirmed')
        content << :closed.tl if @states.include?('closed')
        h[:data_filters] << :journal_entries_states.tl + ' : ' + content.to_sentence
      end

      h[:data_filters] << :account_lettering_state.tl + ' : ' + lettered_content.to_sentence
      h.compact
    end

    def run_pdf
      dataset = compute_dataset
      data_filters = dataset[:data_filters]

      generate_report(template_path) do |r|

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

        r.add_table('ITEM1', dataset[:items], header: true) do |t|
          t.add_column(:name)
          t.add_column(:printed_on)
          t.add_column(:journal_entry_items_number)
          t.add_column(:journal_entry_reference_number)
          t.add_column(:letter)
          t.add_column(:real_debit) { |d| number_to_accountancy(d[:real_debit]) }
          t.add_column(:real_credit) { |d| number_to_accountancy(d[:real_credit]) }
        end

        r.add_table('TOTAL', dataset[:total_items], header: false) do |t|
          t.add_column(:total_debit) { |d| number_to_accountancy(d[:total_debit]) }
          t.add_column(:total_credit) { |d| number_to_accountancy(d[:total_credit]) }
          t.add_column(:total_balance) { |d| number_to_accountancy(d[:total_balance]) }
        end

      end
    end

    def run_odt
      dataset = compute_dataset
      data_filters = dataset[:data_filters]

      # TODO have to modify pdf_printer to return correct ODT file
      # @remi
      generate_report(template_path) do |r|

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

        r.add_table('ITEM1', dataset[:items], header: true) do |t|
          t.add_column(:name)
          t.add_column(:printed_on)
          t.add_column(:journal_entry_items_number)
          t.add_column(:journal_entry_reference_number)
          t.add_column(:letter)
          t.add_column(:real_debit) { |d| number_to_accountancy(d[:real_debit]) }
          t.add_column(:real_credit) { |d| number_to_accountancy(d[:real_credit]) }
        end

        r.add_table('TOTAL', dataset[:total_items], header: false) do |t|
          t.add_column(:total_debit) { |d| number_to_accountancy(d[:total_debit]) }
          t.add_column(:total_credit) { |d| number_to_accountancy(d[:total_credit]) }
          t.add_column(:total_balance) { |d| number_to_accountancy(d[:total_balance]) }
        end

      end
    end


  end
end
