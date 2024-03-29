# frozen_string_literal: true

module Printers
  class TrialBalancePrinter < PrinterBase
    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(started_on:, stopped_on:, states: nil, natures: nil, balance:, accounts:, centralize:)
        states = deprecated_filter(states, :states)
        natures = deprecated_filter(natures, :natures)

        filters = [started_on, stopped_on, balance]
        filters << states.sort.join('-') if states
        filters << natures.sort.join('-') if natures
        filters << accounts.gsub(' ', '-') if accounts
        filters << centralize.gsub(' ', '-') if centralize
        filters.reject(&:blank?).join(' - ')
      end
    end

    def initialize(*_args, states: nil, natures: nil, balance:, accounts:, centralize:, period:, started_on:, stopped_on:, previous_year:, template:, levels:, **_options)
      super(template: template)

      @states = states
      @natures = natures
      @balance = balance
      @accounts = accounts
      @centralize = centralize
      @period = period
      @started_on = started_on
      @stopped_on = stopped_on
      @previous_year = previous_year
      @levels = levels
    end

    def key
      self.class.build_key(started_on: @started_on,
                           stopped_on: @stopped_on,
                           states: @states,
                           natures: @natures,
                           balance: @balance,
                           accounts: @accounts,
                           centralize: @centralize)
    end

    def document_name
      "#{template.nature.human_name} (#{humanized_period})"
    end

    def humanized_period
      return :on_all_exercises.tl if @period == 'all'

      financial_year = FinancialYear.find_by(started_on: Date.parse(@started_on), stopped_on: Date.parse(@stopped_on))
      return financial_year.code if financial_year

      I18n.translate('labels.from_to_date', from: Date.parse(@started_on).l, to: Date.parse(@stopped_on).l)
    end

    def compute_dataset
      Journal.trial_balance_dataset(states: @states,
                                    natures: @natures,
                                    balance: @balance,
                                    accounts: @accounts,
                                    centralize: @centralize,
                                    period: @period,
                                    started_on: @started_on,
                                    stopped_on: @stopped_on,
                                    previous_year: @previous_year,
                                    levels: @levels)
    end

    def generate(r)
      dataset = compute_dataset.map { |k, v| v.merge(ids: k) }

      data_filters = []

      if @states&.any?
        content = []
        content << :draft.tl if @states.include?('draft') && @states['draft'].to_i == 1
        content << :confirmed.tl if @states.include?('confirmed') && @states['confirmed'].to_i == 1
        content << :closed.tl if @states.include?('closed') && @states['closed'].to_i == 1
        data_filters << :journal_entries_states.tl + ' : ' + content.to_sentence
      end

      if @balance
        data_filters << :display_accounts.tl + ' : ' + @balance.to_sym.tl
      end

      if @accounts.present?
        data_filters << :accounts_starting_with.tl + ' : ' + @accounts.split(' ').to_sentence
      end

      if @centralize.present?
        data_filters << :group_by_centralizing_accounts.tl + ' : ' + @centralize.split(' ').to_sentence
      end

      e = Entity.of_company
      company_address = e.default_mail_address&.coordinate

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', document_name
      r.add_field 'FILE_NAME', key
      r.add_field 'PERIOD', humanized_period
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'DATA_FILTERS', data_filters * ' | '

      r.add_table('Tableau2', dataset, header: false) do |t|
        t.add_column(:a) { |item| item[:ids][0] if item[:ids][1].to_i > 0 }
        t.add_column(:b) do |item|
          if item[:ids][1].to_i > 0
            Account.find(item[:ids][1]).name
          elsif item[:ids][1] == '-1'
            :total.tl
          elsif item[:ids][1] == '-2'
            I18n.translate('labels.subtotal', name: item[:ids][0])
          elsif item[:ids][1] == '-3'
            I18n.translate('labels.centralized_account', name: item[:ids][0])
          end
        end
        t.add_column(:debit) { |item| currency_format(item[:n].any? ? item[:n][2].to_f : 0.0) }
        t.add_column(:credit) { |item| currency_format(item[:n].any? ? item[:n][3].to_f : 0.0) }
        t.add_column(:debit_n) { |item| currency_format(item[:n_1].any? ? item[:n_1][2].to_f : 0.0) }
        t.add_column(:credit_n) { |item| currency_format(item[:n_1].any? ? item[:n_1][3].to_f : 0.0) }
        t.add_column(:balance) { |item| currency_format(item[:n].any? ? item[:n][4].to_f : 0.0) }
        t.add_column(:balance_n) { |item| currency_format(item[:n_1].any? ? item[:n_1][4].to_f : 0.0) }
      end
    end

    def currency_format(value)
      value.round_l(currency: Preference[:currency])
    end

    def run_ods
      require 'rodf'
      output = RODF::Spreadsheet.new

      dataset = compute_dataset

      output.instance_eval do
        office_style :head, family: :cell do
          property :text, 'font-weight': :bold
          property :paragraph, 'text-align': :center
        end

        office_style :right, family: :cell do
          property :paragraph, 'text-align': :right
        end

        office_style :bold, family: :cell do
          property :text, 'font-weight': :bold
        end

        office_style :italic, family: :cell do
          property :text, 'font-style': :italic
        end

        table do
          row do
            cell JournalEntryItem.human_attribute_name(:account_number), style: :head
            cell JournalEntryItem.human_attribute_name(:account_name), style: :head
            cell :total.tl, style: :head, span: 4
            cell :balance.tl, style: :head, span: 4
          end

          row do
            cell ''
            cell ''
            cell JournalEntry.human_attribute_name(:debit), style: :head
            cell JournalEntry.human_attribute_name(:credit), style: :head
            cell JournalEntry.human_attribute_name(:debit) + ' N-1', style: :head
            cell JournalEntry.human_attribute_name(:credit) + ' N-1', style: :head
            cell JournalEntry.human_attribute_name(:debit), style: :head
            cell JournalEntry.human_attribute_name(:credit), style: :head
            cell JournalEntry.human_attribute_name(:debit) + ' N-1', style: :head
            cell JournalEntry.human_attribute_name(:credit) + ' N-1', style: :head
          end

          dataset.each do |keys, values|
            if keys[1].to_i > 0
              account = Account.find(keys[1])
              row do
                cell account.number
                cell account.name
                cell values[:n].any? ? values[:n][2].l : '', type: :float
                cell values[:n].any? ? values[:n][3].l : '', type: :float
                cell values[:n_1].any? ? values[:n_1][2].l : '', type: :float
                cell values[:n_1].any? ? values[:n_1][3].l : '', type: :float
                cell (values[:n].any? ? (values[:n][4].to_f > 0 ? values[:n][4] : 0) : '').l, type: :float
                cell (values[:n].any? ? (values[:n][4].to_f < 0 ? (-values[:n][4].to_f).to_s : 0) : '').l, type: :float
                cell (values[:n_1].any? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4] : 0) : '').l, type: :float
                cell (values[:n_1].any? ? (values[:n_1][4].to_f < 0 ? (-values[:n_1][4].to_f).to_s : 0) : '').l, type: :float
              end

            elsif keys[1].to_i == -1
              row do
                cell ''
                cell :total.tl, style: :bold
                cell values[:n][2].present? ? values[:n][2].l : '', style: :bold, type: :float
                cell values[:n][3].present? ? values[:n][3].l : '', style: :bold, type: :float
                cell values[:n_1][2].present? ? values[:n_1][2].l : '', style: :bold, type: :float
                cell values[:n_1][3].present? ? values[:n_1][3].l : '', style: :bold, type: :float
                cell (values[:n][4].present? ? (values[:n][4].to_f > 0 ? values[:n][4] : 0) : '').l, style: :bold, type: :float
                cell (values[:n][4].present? ? (values[:n][4].to_f < 0 ? (-values[:n][4].to_f).to_s : 0) : '').l, style: :bold, type: :float
                cell (values[:n_1][4].present? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4] : 0) : '').l, style: :bold, type: :float
                cell (values[:n_1][4].present? ? (values[:n_1][4].to_f < 0 ? (-values[:n_1][4].to_f).to_s : 0) : '').l, style: :bold, type: :float
              end
            elsif keys[1].to_i == -2
              row do
                cell
                cell :subtotal.tl(name: keys[0]).l, style: :right
                cell values[:n].any? ? values[:n][2].l : '', style: :bold, type: :float
                cell values[:n].any? ? values[:n][3].l : '', style: :bold, type: :float
                cell values[:n_1].any? ? values[:n_1][2].l : '', style: :bold, type: :float
                cell values[:n_1].any? ? values[:n_1][3].l : '', style: :bold, type: :float
                cell (values[:n].any? ? (values[:n][4].to_f > 0 ? values[:n][4] : 0) : '').l, style: :bold, type: :float
                cell (values[:n].any? ? (values[:n][4].to_f < 0 ? (-values[:n][4].to_f).to_s : 0) : '').l, style: :bold, type: :float
                cell (values[:n_1].any? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4] : 0) : '').l, style: :bold, type: :float
                cell (values[:n_1].any? ? (values[:n_1][4].to_f < 0 ? (-values[:n_1][4].to_f).to_s : 0) : '').l, style: :bold, type: :float
              end
            elsif keys[1].to_i == -3
              row do
                cell keys[0], style: :italic
                cell :centralized_account.tl(name: keys[0]).l, style: :italic
                cell values[:n].any? ? values[:n][2].l : '', style: :italic, type: :float
                cell values[:n].any? ? values[:n][3].l : '', style: :italic, type: :float
                cell values[:n_1].any? ? values[:n_1][2].l : '', style: :italic, type: :float
                cell values[:n_1].any? ? values[:n_1][3].l : '', style: :italic, type: :float
                cell (values[:n].any? ? (values[:n][4].to_f > 0 ? values[:n][4] : 0) : '').l, style: :italic, type: :float
                cell (values[:n].any? ? (values[:n][4].to_f < 0 ? (-values[:n][4].to_f).to_s : 0) : '').l, style: :italic, type: :float
                cell (values[:n_1].any? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4] : 0) : '').l, style: :italic, type: :float
                cell (values[:n_1].any? ? (values[:n_1][4].to_f < 0 ? (-values[:n_1][4].to_f).to_s : 0) : '').l, style: :italic, type: :float
              end
            end
          end
        end
      end
      output
    end

    def run_csv(csv)
      dataset = compute_dataset

      csv << [
        JournalEntryItem.human_attribute_name(:account_number),
        JournalEntryItem.human_attribute_name(:account_name),
        :total.tl,
        '',
        '',
        '',
        :balance.tl
      ]

      csv << [
        '',
        '',
        JournalEntry.human_attribute_name(:debit),
        JournalEntry.human_attribute_name(:credit),
        JournalEntry.human_attribute_name(:debit) + ' N-1',
        JournalEntry.human_attribute_name(:credit) + ' N-1',
        JournalEntry.human_attribute_name(:debit),
        JournalEntry.human_attribute_name(:credit),
        JournalEntry.human_attribute_name(:debit) + ' N-1',
        JournalEntry.human_attribute_name(:credit) + ' N-1'
      ]

      dataset.each do |keys, values|
        if keys[1].to_i > 0
          account = Account.find(keys[1])
          account_name = account.name

          if csv.encoding.eql?(Encoding::CP1252)
            account_name = account_name.encode('CP1252', invalid: :replace, undef: :replace, replace: '?')
          end

          csv << [
            account.number,
            account_name,
            values[:n][2].present? ? values[:n][2].to_f : '',
            values[:n][3].present? ? values[:n][3].to_f : '',
            values[:n_1][2].present? ? values[:n_1][2].to_f : '',
            values[:n_1][3].present? ? values[:n_1][3].to_f : '',
            values[:n][4].present? ? (values[:n][4].to_f > 0 ? values[:n][4].to_f : 0) : '',
            values[:n][4].present? ? (values[:n][4].to_f < 0 ? -values[:n][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f < 0 ? -values[:n_1][4].to_f : 0) : ''
          ]
        elsif keys[1].to_i == -1
          # Part for the total
          csv << [
            '',
            :total.tl,
            values[:n][2].present? ? values[:n][2].to_f : '',
            values[:n][3].present? ? values[:n][3].to_f : '',
            values[:n_1][2].present? ? values[:n_1][2].to_f : '',
            values[:n_1][3].present? ? values[:n_1][3].to_f : '',
            values[:n][4].present? ? (values[:n][4].to_f > 0 ? values[:n][4].to_f : 0) : '',
            values[:n][4].present? ? (values[:n][4].to_f < 0 ? -values[:n][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f < 0 ? -values[:n_1][4].to_f : 0) : ''
          ]
        elsif keys[1].to_i == -2
          csv << [
            '',
            :subtotal.tl(name: keys[0]).l,
            values[:n][2].present? ? values[:n][2].to_f : '',
            values[:n][3].present? ? values[:n][3].to_f : '',
            values[:n_1][2].present? ? values[:n_1][2].to_f : '',
            values[:n_1][3].present? ? values[:n_1][3].to_f : '',
            values[:n][4].present? ? (values[:n][4].to_f > 0 ? values[:n][4].to_f : 0) : '',
            values[:n][4].present? ? (values[:n][4].to_f < 0 ? -values[:n][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f < 0 ? -values[:n_1][4].to_f : 0) : ''
          ]
        elsif keys[1].to_i == -3
          csv << [
            keys[0],
            :centralized_account.tl(name: keys[0]).l,
            values[:n][2].present? ? values[:n][2].to_f : '',
            values[:n][3].present? ? values[:n][3].to_f : '',
            values[:n_1][2].present? ? values[:n_1][2].to_f : '',
            values[:n_1][3].present? ? values[:n_1][3].to_f : '',
            values[:n][4].present? ? (values[:n][4].to_f > 0 ? values[:n][4].to_f : 0) : '',
            values[:n][4].present? ? (values[:n][4].to_f < 0 ? -values[:n][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f > 0 ? values[:n_1][4].to_f : 0) : '',
            values[:n_1][4].present? ? (values[:n_1][4].to_f < 0 ? -values[:n_1][4].to_f : 0) : ''
          ]
        end
      end
    end
  end
end
