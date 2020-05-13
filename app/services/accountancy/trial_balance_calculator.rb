module Accountancy
  class TrialBalanceCalculator
    class << self

      # @param [] connection
      # @return [TrialBalanceCalculator]
      def build(connection:)
        new(
          connection: connection,
          account_condition_builder: Accountancy::ConditionBuilder::AccountConditionBuilder.new(connection: connection),
          journal_condition_builder: Accountancy::ConditionBuilder::JournalConditionBuilder.new(connection: connection),
          journal_entry_condition_builder: Accountancy::ConditionBuilder::JournalEntryConditionBuilder.new(connection: connection)
        )
      end
    end

    attr_reader :connection, :account_condition_builder, :journal_condition_builder, :journal_entry_condition_builder

    # @param [ActiveRecord::ConnectionAdapters::PostGISAdapter] connection
    # @param [ConditionBuilder::AccountConditionBuilder] account_condition_builder
    # @param [ConditionBuilder::JournalConditionBuilder] journal_condition_builder
    # @param [ConditionBuilder::JournalEntryConditionBuilder] journal_entry_condition_builder
    def initialize(connection:, account_condition_builder:, journal_condition_builder:, journal_entry_condition_builder:)
      @connection = connection
      @account_condition_builder = account_condition_builder
      @journal_condition_builder = journal_condition_builder
      @journal_entry_condition_builder = journal_entry_condition_builder
    end

    def trial_balance(options = {})
      journal_entry_items = 'jei'
      vat_journal_entry_items = 'vjei'
      tax_items = 'ti'
      tax_accounts = 'ta'
      journal_entries = 'je'
      journals = 'j'
      accounts = 'a'

      journal_entries_states = ' AND (' + journal_entry_condition_builder.state_condition(options[:states], table_name: journal_entries) + ')'
      journals_natures = ' AND (' + journal_condition_builder.nature_condition(options[:natures], table_name: journals) + ')'
      account_range_condition = account_condition_builder.range_condition(options[:accounts], table_name: accounts)
      account_range = ' AND (' + account_range_condition + ')' if account_range_condition

      # FIXME: There no centralizing account anymore in DB, the query needs to be adjusted
      centralize = options[:centralize].to_s.strip.split(/[^A-Z0-9]+/)
      centralized = '(' + centralize.collect { |c| "#{accounts}.number LIKE #{connection.quote(c + '%')}" }.join(' OR ') + ')'

      from_where = " FROM #{JournalEntryItem.table_name} AS #{journal_entry_items} JOIN #{Account.table_name} AS #{accounts} ON (account_id=#{accounts}.id) JOIN #{JournalEntry.table_name} AS #{journal_entries} ON (entry_id=#{journal_entries}.id) JOIN #{Journal.table_name} AS #{journals} ON (#{journal_entries}.journal_id=#{journals}.id)"
      from_where += ' WHERE (' + journal_entry_condition_builder.period_condition(options[:period], started_on: options[:started_on], stopped_on: options[:stopped_on], table_name: journal_entries) + ')'

      # Total - position in array -1
      items = []
      query = "SELECT '', -1, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), '#{'Z' * 16}' AS skey"
      query << from_where
      query << journal_entries_states
      query << journals_natures
      query << account_range unless account_range.nil?
      items += connection.select_rows(query)

      # Sub-totals  - position in array -2
      options.select { |k, v| k.to_s.match(/^level_\d+$/) && v.to_i == 1 }.each do |name, _value|
        level = name.split(/\_/)[-1].to_i
        query = "SELECT SUBSTR(#{accounts}.number, 1, #{level}) AS subtotal, -2, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), SUBSTR(#{accounts}.number, 1, #{level})||'#{'Z' * (16 - level)}' AS skey"
        query << from_where
        query << journal_entries_states
        query << journals_natures
        query << account_range unless account_range.nil?
        query << " AND LENGTH(#{accounts}.number) >= #{level}"
        query << ' GROUP BY subtotal'
        items += connection.select_rows(query)
      end

      # NOT centralized accounts (default)
      query = "SELECT #{accounts}.number, #{accounts}.id AS account_id, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), #{accounts}.number AS skey"
      query << from_where
      query << journal_entries_states
      query << journals_natures
      query << account_range unless account_range.nil?
      query << " AND NOT #{centralized}" unless centralize.empty?
      query << " GROUP BY #{accounts}.id, #{accounts}.number"
      query << " ORDER BY #{accounts}.number"
      items += connection.select_rows(query)

      # Centralized accounts  - position in array -3
      for prefix in centralize
        query = "SELECT SUBSTR(#{accounts}.number, 1, #{prefix.size}) AS centralize, -3, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), #{connection.quote(prefix)} AS skey"
        query << from_where
        query << journal_entries_states
        query << journals_natures
        query << account_range unless account_range.nil?
        query << " AND #{accounts}.number LIKE #{connection.quote(prefix + '%')}"
        query << ' GROUP BY centralize'
        items += connection.select_rows(query)
      end

      # VAT details on accounts - position in array -4
      if options[:vat_details]
        from_where_vat  = " FROM #{JournalEntryItem.table_name} AS #{journal_entry_items} JOIN #{Account.table_name} AS #{accounts} ON (account_id=#{accounts}.id) JOIN #{JournalEntry.table_name} AS #{journal_entries} ON (entry_id=#{journal_entries}.id) JOIN #{Journal.table_name} AS #{journals} ON (#{journal_entries}.journal_id=#{journals}.id)"
        from_where_vat += " JOIN #{JournalEntryItem.table_name} AS #{vat_journal_entry_items} ON (#{journal_entry_items}.resource_id=#{vat_journal_entry_items}.resource_id AND #{journal_entry_items}.entry_id=#{vat_journal_entry_items}.entry_id AND ABS(#{journal_entry_items}.real_balance)=ABS(#{vat_journal_entry_items}.absolute_pretax_amount) AND #{vat_journal_entry_items}.resource_prism = 'item_tax')"
        from_where_vat += " JOIN #{Tax.table_name} AS #{tax_items} ON (#{vat_journal_entry_items}.tax_id=#{tax_items}.id)"
        from_where_vat += " JOIN #{Account.table_name} AS #{tax_accounts} ON (#{vat_journal_entry_items}.account_id=#{tax_accounts}.id)"
        from_where_vat += ' WHERE (' + journal_entry_condition_builder.period_condition(options[:period], started_on: options[:started_on], stopped_on: options[:stopped_on], table_name: journal_entries) + ')'
        query = "SELECT COALESCE(#{tax_accounts}.id, 0) AS account_id, -4, sum(COALESCE(#{journal_entry_items}.debit, 0)), sum(COALESCE(#{journal_entry_items}.credit, 0)), sum(COALESCE(#{journal_entry_items}.debit, 0)) - sum(COALESCE(#{journal_entry_items}.credit, 0)), #{accounts}.number AS skey"
        query << from_where_vat
        query << journal_entries_states
        query << journals_natures
        query << account_range unless account_range.nil?
        query << " AND NOT #{centralized}" unless centralize.empty?
        query << " GROUP BY #{accounts}.id, #{accounts}.number, #{tax_accounts}.id, #{tax_accounts}.number"
        query << " ORDER BY #{accounts}.number, #{tax_accounts}.number"
        items += connection.select_rows(query)
      end

      items.sort_by { |a| a[5] }
    end

    def trial_balance_dataset(states:, natures:, balance:, accounts:, centralize:, period:, started_on:, stopped_on:, previous_year:, vat_details: false)
      balance_params = { states: states, natures: natures, accounts: accounts, centralize: centralize, period: period, started_on: started_on, stopped_on: stopped_on, vat_details: vat_details}

      balance_data = if period.present?
                       trial_balance(balance_params)
                     else
                       []
                     end

      if balance_data.present?
        credit_balance = balance_data[0...-1].map { |item| item[4].to_f > 0 ? item[4].to_f : 0 }.reduce(0, :+).round(2)
        debit_balance = balance_data[0...-1].map { |item| item[4].to_f < 0 ? item[4].to_f : 0 }.reduce(0, :+).round(2)
        balance_data[-1].insert(5, credit_balance, debit_balance)


        if balance == 'balanced'
          balance_data = balance_data.select { |item| item[1].to_i < 0 || Account.find(item[1]).journal_entry_items.pluck(:real_balance).reduce(:+) == 0 }
        elsif balance == 'unbalanced'
          balance_data = balance_data.select { |item| item[1].to_i < 0 || Account.find(item[1]).journal_entry_items.pluck(:real_balance).reduce(:+) != 0 }
        end
      end

      prev_balance_data = []
      if previous_year && started_on && Date.parse(stopped_on) - Date.parse(started_on) < 366
        prev_balance_data = balance_data.map do |item|
          prev_balance_params = balance_params.dup
          prev_balance_params[:started_on] = (Date.parse(started_on) - 1.year).to_s
          prev_balance_params[:stopped_on] = (Date.parse(stopped_on) - 1.year).to_s
          prev_balance_params[:period] = "#{prev_balance_params[:started_on]}_#{prev_balance_params[:stopped_on]}"
          if item[1].to_i < 0 && item[0].present?
            prev_balance_params[:centralize] = item[0]
          elsif item[1].to_i > 0
            prev_balance_params[:accounts] = item[0]
          end
          prev_balance_data = trial_balance(prev_balance_params)
          prev_items = prev_balance_data.select { |i| i[0] == item[0] }
          prev_items.any? ? prev_items.first : []
        end
        solde_prev_credit_balance = prev_balance_data[0...-1].map { |item| item[4].to_f > 0 ? item[4].to_f : 0 }.reduce(0, :+).round(2)
        solde_prev_debit_balance = prev_balance_data[0...-1].map { |item| item[4].to_f < 0 ? item[4].to_f : 0 }.reduce(0, :+).round(2)
        total_prev_credit_balance = prev_balance_data[0...-1].map { |item| item[2].to_f }.reduce(0, :+).round(2)
        total_prev_debit_balance = prev_balance_data[0...-1].map { |item| item[3].to_f }.reduce(0, :+).round(2)
        prev_balance_data[-1].insert(5, solde_prev_credit_balance, solde_prev_debit_balance)
        prev_balance_data[-1].insert(7, total_prev_credit_balance, total_prev_debit_balance)
      end
      { balance: balance_data, prev_balance: prev_balance_data }
    end
  end
end
