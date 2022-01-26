# frozen_string_literal: true

module Printers
  class GeneralLedgerPrinter < PrinterBase
    include ApplicationHelper
    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(started_on:, stopped_on:, lettering_state:, states:, ledger:, account_number:)
        filters = [ledger, started_on, stopped_on]
        filters.unshift(account_number) if account_number
        filters << lettering_state.join('-') if lettering_state
        filters << states.select { |k, v| v == '1' }.keys.sort.join('-') if states
        filters.reject(&:blank?).join(' - ')
      end
    end

    # ledger params could be one of 'general_ledger', '401', '411', "suppliers", "clients"
    def initialize(*_args, accounts: nil, lettering_state: nil, states: nil, ledger:, account_number: nil, started_on:, stopped_on:, template:, **_options)
      super(template: template)

      @accounts = accounts
      @lettering_state = lettering_state
      @states = states
      @ledger = ledger
      @account_number = account_number
      @started_on = started_on
      @stopped_on = stopped_on
      # buid variable according to ledger params
      case @ledger
      when '401' || 'suppliers'
        @accounts = ['401']
      when '411' || 'clients'
        @accounts = ['411']
      end
    end

    def key
      self.class.build_key(started_on: @started_on,
                           stopped_on: @stopped_on,
                           states: @states,
                           lettering_state: @lettering_state,
                           account_number: @account_number,
                           ledger: @ledger)
    end

    def document_name
      if @account_number
        "#{template.nature.human_name} (#{@account_number}, #{humanized_period})"
      else
        case @ledger
        when '401'
          "#{:subledger_of_accounts_x.tl(account: :suppliers.tl)} (#{humanized_period})"
        when '411'
          "#{:subledger_of_accounts_x.tl(account: :clients.tl)} (#{humanized_period})"
        else
          "#{template.nature.human_name} (#{humanized_period})"
        end
      end
    end

    def humanized_period
      financial_year = FinancialYear.find_by(started_on: Date.parse(@started_on), stopped_on: Date.parse(@stopped_on))
      return financial_year.code if financial_year

      I18n.translate('labels.from_to_date', from: Date.parse(@started_on).l, to: Date.parse(@stopped_on).l)
    end

    def compute_dataset
      accounts_filter_conditions = '1=1'
      list_accounts = @accounts.present? ? @accounts : ''

      unless list_accounts.empty?
        accounts_filter_conditions += ' AND ' + list_accounts.collect do |account|
          "accounts.number LIKE '" + account.to_s + "%'"
        end.join(' OR ')
      end

      c = @lettering_state.count if @lettering_state
      lettering_state_filter_conditions = if c == 4 && @lettering_state.to_set.superset?(%w[unlettered partially_lettered lettered unleterred_at].to_set)
                                            "1=1"
                                          elsif c == 3 && @lettering_state.to_set.superset?(%w[unlettered partially_lettered lettered].to_set)
                                            '1=1'
                                          elsif c == 3 && @lettering_state.to_set.superset?(%w[unlettered partially_lettered unlettered_at].to_set)
                                            "letter IS NULL OR (letter IS NOT NULL AND letter ILIKE '%*') OR (letter IS NOT NULL AND letter NOT ILIKE '%*' AND lettered_at > '#{Time.zone.parse(@stopped_on.to_s) + 1.day}')"
                                          elsif c == 3 && @lettering_state.to_set.superset?(%w[partially_lettered lettered unlettered_at].to_set)
                                            'letter IS NOT NULL'
                                          elsif c == 3 && @lettering_state.to_set.superset?(%w[unlettered lettered unlettered_at].to_set)
                                            "letter IS NULL OR (letter IS NOT NULL AND letter NOT ILIKE '%*')"
                                          elsif c == 2 && @lettering_state.to_set.superset?(%w[partially_lettered lettered].to_set)
                                            'letter IS NOT NULL'
                                          elsif c == 2 && @lettering_state.to_set.superset?(%w[unlettered partially_lettered].to_set)
                                            "letter IS NULL OR (letter IS NOT NULL AND letter ILIKE '%*')"
                                          elsif c == 2 && @lettering_state.to_set.superset?(%w[unlettered lettered].to_set)
                                            "letter IS NULL OR (letter IS NOT NULL AND letter NOT ILIKE '%*')"
                                          elsif c == 2 && @lettering_state.to_set.superset?(%w[lettered unlettered_at].to_set)
                                            # same as lettered itself
                                            "letter IS NOT NULL AND letter NOT ILIKE '%*'"
                                          elsif c == 1 && @lettering_state.to_set.superset?(['unlettered'].to_set)
                                            'letter IS NULL'
                                          elsif c == 1 && @lettering_state.to_set.superset?(['unlettered_at'].to_set)
                                            "letter IS NOT NULL AND letter NOT ILIKE '%*' AND lettered_at > '#{Time.zone.parse(@stopped_on.to_s) + 1.day}'"
                                          elsif c == 1 && @lettering_state.to_set.superset?(['lettered'].to_set)
                                            "letter IS NOT NULL AND letter NOT ILIKE '%*'"
                                          elsif c == 1 && @lettering_state.to_set.superset?(['partially_lettered'].to_set)
                                            "letter IS NOT NULL AND letter ILIKE '%*'"
                                          else
                                            '1=1'
                                          end

      if @states&.any?
        a = @states.select { |_k, v| v.to_i == 1 }.map { |pair| "'#{pair.first}'" }.join(', ')
        states_array = "state IN (#{a})"
      else
        states_array = '1=1'
      end

      ledger = []
      global_balance = 0.0

      accounts = Account
                   .where(accounts_filter_conditions)
                   .includes(journal_entry_items: %i[entry variant])
                   .where(journal_entry_items: { printed_on: @started_on..@stopped_on })
                   .reorder('accounts.number ASC, journal_entries.number ASC')

      accounts.each do |account|
        journal_entry_items = account.journal_entry_items.where(lettering_state_filter_conditions).where(states_array).where(printed_on: @started_on..@stopped_on).reorder('printed_on ASC, entry_number ASC')
        next if (journal_entry_items.count < 1 || journal_entry_items.sum(:balance) == 0.0) && @lettering_state.present? && @lettering_state.include?("unlettered_at")

        account_entry = HashWithIndifferentAccess.new
        account_balance = 0.0
        total_debit = 0.0
        total_credit = 0.0
        entry_count = 0

        account_entry[:account_number] = account.number
        account_entry[:account_name] = account.name
        account_entry[:currency] = journal_entry_items.first.currency if journal_entry_items.any?
        account_entry[:items] = []

        journal_entry_items.each do |e|
          item = HashWithIndifferentAccess.new
          item[:entry_number] = e.entry_number
          item[:continuous_number] = e.continuous_number.to_s if e.continuous_number
          item[:reference_number] = e.entry.reference_number.to_s if e.entry.reference_number
          item[:printed_on] = e.printed_on.strftime('%d/%m/%Y')
          item[:name] = e.name.to_s
          item[:variant] = e.variant.name if e.variant
          item[:journal_name] = e.entry.journal.name.to_s
          item[:letter] = e.letter
          item[:real_debit] = e.real_debit
          item[:real_credit] = e.real_credit
          item[:cumulated_balance] = (account_balance += (e.real_debit - e.real_credit))

          account_entry[:items] << item

          total_debit += e.real_debit
          total_credit += e.real_credit
          entry_count += 1
        end

        account_entry[:count] = entry_count.to_s
        account_entry[:total_debit] = total_debit
        account_entry[:total_credit] = total_credit
        global_balance += account_balance
        ledger << account_entry
      end

      ledger << global_balance

      data_filters = []

      if @ledger
        if @ledger == 'general_ledger'
          data_filters << "#{:centralizing_accounts.tl} : 401, 411"
        else
          data_filters << "#{:centralizing_account.tl} : #{@ledger}"
        end
      end

      if @lettering_state
        content = []
        content << :unlettered.tl if @lettering_state.include?('unlettered')
        content << :partially_lettered.tl if @lettering_state.include?('partially_lettered')
        content << :lettered.tl if @lettering_state.include?('lettered')
        content << :unlettered_at.tl if @lettering_state.include?('unlettered_at')
        data_filters << :lettering_state.tl + ' : ' + content.to_sentence
      end

      if @states&.any?
        content = []
        content << :draft.tl if @states.include?('draft') && @states['draft'].to_i == 1
        content << :confirmed.tl if @states.include?('confirmed') && @states['confirmed'].to_i == 1
        content << :closed.tl if @states.include?('closed') && @states['closed'].to_i == 1
        data_filters << :journal_entries_states.tl + ' : ' + content.to_sentence
      end

      unless list_accounts.empty?
        data_filters << :accounts.tl + ' : ' + list_accounts.to_sentence
      end

      ledger << data_filters
      ledger.compact
    end

    def generate(r)
      dataset = compute_dataset
      data_filters = dataset.pop
      global_balance = dataset.pop

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address&.coordinate

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', document_name
      r.add_field 'FILE_NAME', key
      r.add_field 'PERIOD', I18n.translate('labels.from_to_date', from: @started_on.l, to: @stopped_on.l)
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'STARTED_ON', @started_on.l
      r.add_field 'STOPPED_ON', @stopped_on.l
      r.add_field 'DATA_FILTERS', data_filters * ' | '

      r.add_section('Section1', dataset) do |s|
        s.add_field(:account_number, :account_number)
        s.add_field(:account_name, :account_name)
        s.add_field(:count, :count)
        s.add_field(:currency, :currency)
        s.add_field(:total_debit, :total_debit)
        s.add_field(:total_credit, :total_credit)
        s.add_field(:total_cumulated_balance) do |acc|
          acc[:total_debit] - acc[:total_credit]
        end

        s.add_table('Tableau1', :items, header: true) do |t|
          t.add_column(:entry_number) { |item| item[:entry_number] }
          t.add_column(:continuous_number) { |item| item[:continuous_number] }
          t.add_column(:reference_number) { |item| item[:reference_number] }
          t.add_column(:printed_on) { |item| item[:printed_on] }
          t.add_column(:name) { |item| item[:name] }
          t.add_column(:variant) { |item| item[:variant] }
          t.add_column(:journal_name) { |item| item[:journal_name] }
          t.add_column(:letter) { |item| item[:letter] }
          t.add_column(:real_debit) { |item| item[:real_debit] }
          t.add_column(:real_credit) { |item| item[:real_credit] }
          t.add_column(:cumulated_balance) { |item| item[:cumulated_balance] }
        end
      end
      r.add_field 'GLOBAL_BALANCE', number_to_accountancy(global_balance)
    end

    def run_ods
      require 'rodf'
      output = RODF::Spreadsheet.new

      dataset = compute_dataset[0...-2]

      output.instance_eval do
        office_style :head, family: :cell do
          property :text, 'font-weight': :bold
          property :paragraph, 'text-align': :center
        end

        table 'ledger' do
          row do
            cell JournalEntryItem.human_attribute_name(:account_number), style: :head
            cell JournalEntryItem.human_attribute_name(:account_name), style: :head
            cell JournalEntryItem.human_attribute_name(:entry_number), style: :head
            cell JournalEntryItem.human_attribute_name(:continuous_number), style: :head
            cell JournalEntryItem.human_attribute_name(:printed_on), style: :head
            cell JournalEntryItem.human_attribute_name(:name), style: :head
            cell JournalEntryItem.human_attribute_name(:reference_number), style: :head
            cell JournalEntryItem.human_attribute_name(:journal_name), style: :head
            cell JournalEntryItem.human_attribute_name(:letter), style: :head
            cell JournalEntry.human_attribute_name(:real_debit), style: :head
            cell JournalEntry.human_attribute_name(:real_credit), style: :head
            cell JournalEntry.human_attribute_name(:cumulated_balance), style: :head
          end

          dataset.each do |account|
            account[:items].each do |item|
              row do
                cell account[:account_number], style: :head
                cell account[:account_name], style: :head
                cell item[:entry_number]
                cell item[:continuous_number]
                cell item[:printed_on]
                cell item[:name]
                cell item[:reference_number]
                cell item[:journal_name]
                cell item[:letter]
                cell item[:real_debit]
                cell item[:real_credit]
                cell item[:cumulated_balance]
              end
            end
          end
        end
      end
      output
    end

    def run_csv(csv)
      dataset = compute_dataset[0...-2]

      csv << [
        JournalEntryItem.human_attribute_name(:account_number),
        JournalEntryItem.human_attribute_name(:account_name),
        JournalEntryItem.human_attribute_name(:entry_number),
        JournalEntryItem.human_attribute_name(:continuous_number),
        JournalEntryItem.human_attribute_name(:printed_on),
        JournalEntryItem.human_attribute_name(:name),
        JournalEntryItem.human_attribute_name(:reference_number),
        JournalEntryItem.human_attribute_name(:journal_name),
        JournalEntryItem.human_attribute_name(:letter),
        JournalEntry.human_attribute_name(:real_debit),
        JournalEntry.human_attribute_name(:real_credit),
        JournalEntry.human_attribute_name(:cumulated_balance)
      ]

      dataset.each do |account|
        account[:items].each do |item|
          item_name = item[:name]
          account_name = account[:account_name]
          journal_name = item[:journal_name]

          if csv.encoding.eql?(Encoding::CP1252)
            item_name = item_name.encode('CP1252', invalid: :replace, undef: :replace, replace: '?')
            account_name = account_name.encode('CP1252', invalid: :replace, undef: :replace, replace: '?')
            journal_name = journal_name.encode('CP1252', invalid: :replace, undef: :replace, replace: '?')
          end

          csv << [
            account[:account_number],
            account_name,
            item[:entry_number],
            item[:continuous_number],
            item[:printed_on],
            item_name,
            item[:reference_number],
            journal_name,
            item[:letter],
            item[:real_debit],
            item[:real_credit],
            item[:cumulated_balance]
          ]
        end
      end
    end
  end
end
