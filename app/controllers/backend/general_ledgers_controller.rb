# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class GeneralLedgersController < Backend::BaseController
    include PdfPrinter

    before_action :save_search_preference, only: :show

    def self.list_conditions
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit] }, conditions: 'c') + "\n"
      code << ledger_crit('params')
      code << journal_period_crit('params')
      code << account_crit('params')
      code << "params[:lettering_state] = ['lettered', 'partially_lettered', 'unlettered']\n"
      code << "preference_basename = 'backend/general_ledgers.journal_entry_items-list' \n"

      code << "if current_user.preference(preference_basename + '.lettered_items.masked', false, :boolean).value \n"
      code << "  params[:lettering_state].reject!{|s| s == 'lettered'}\n"
      code << "end \n"
      code << "states = #{JournalEntry.states}\n"
      code << "if current_user.preference(preference_basename + '.draft_items.masked', false, :boolean).value \n"
      code << "  states.reject!{|s| s == :draft}\n"
      code << "end \n"
      code << "states = states.each_with_object({}) do |v, h| \n"
      code << "  h[v] = 1 \n"
      code << "end \n"
      code << "params[:states] = states\n"
      code << journal_letter_crit('params')
      code << journal_entries_states_crit('params')
      code << "c\n"
      code.c
    end

    def self.account_conditions
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit] }, conditions: 'c') + "\n"
      code << account_journal_period_crit('params')
      code << centralizing_account_crit('params')
      code << "c\n"
      code.c
    end

    def self.centralized_account_conditions
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit] }, conditions: 'c') + "\n"
      code << centralizing_account_crit('params')
      code << centralizing_account_journal_period_crit('params')
      code << "c\n"
      code.c
    end

    def self.subledger_accounts_selections
      s = []
      s << ['CASE WHEN (SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit)) >= 0 THEN SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit) ELSE 0 END', 'cumulated_absolute_debit_balance']
      s << ['CASE WHEN (SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit)) < 0 THEN @ SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit) ELSE 0 END', 'cumulated_absolute_credit_balance']
      s << ['accounts.number']
      s << ['accounts.name'] << ['accounts.id']
      s << ['journal_entry_items.absolute_currency AS account_currency']
    end

    def self.union_subquery
      q1 = %q{Account.select("rpad(accounts.number, 8, '0') AS account_number, accounts.centralizing_account_name AS account_name, CASE WHEN (SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit)) >= 0 THEN SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit) ELSE 0 END AS cumulated_absolute_debit_balance, CASE WHEN (SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit)) < 0 THEN @ SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit) ELSE 0 END AS cumulated_absolute_credit_balance, journal_entry_items.absolute_currency AS account_currency").joins('INNER JOIN "journal_entry_items" ON "journal_entry_items"."account_id" = accounts."id"').joins('INNER JOIN "journal_entries" ON "journal_entries"."id" = "journal_entry_items"."entry_id"').where("nature = 'auxiliary'").group('account_name, account_number, account_currency')}

      q2 = %q{Account.select('accounts.number AS account_number, accounts.name, CASE WHEN (SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit)) >= 0 THEN SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit) ELSE 0 END AS cumulated_absolute_debit_balance, CASE WHEN (SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit)) < 0 THEN @ SUM(journal_entry_items.real_debit) - SUM(journal_entry_items.real_credit) ELSE 0 END AS cumulated_absolute_credit_balance, journal_entry_items.absolute_currency AS account_currency').joins('INNER JOIN "journal_entry_items" ON "journal_entry_items"."account_id" = accounts."id"').joins('INNER JOIN "journal_entries" ON "journal_entries"."id" = "journal_entry_items"."entry_id"').where("nature = 'general'").group('accounts.number, accounts.name, accounts.id, accounts.description, account_currency')}

      code = "k = ''\n"
      code << centralized_account_conditions.to_s
      code << "k << '(' \n"
      code << "k << #{q1.c}.where(c).to_sql \n"
      code << "k << ' UNION '\n"
      code << "k << #{q2.c}.where(c).to_sql \n"
      code << "k << ') AS U'\n"
      code << "k\n"
      code.c
    end

    list(:subledger_accounts, model: :accounts, conditions: account_conditions, joins: %i[journal_entry_items], order: 'accounts.number', select: subledger_accounts_selections, group: %w[accounts.number accounts.name accounts.id account_currency], count: 'DISTINCT accounts.number') do |t|
      t.column :number, url: { controller: :general_ledgers, account_number: 'RECORD.number'.c, current_financial_year: 'params[:current_financial_year]'.c, ledger: 'RECORD.number[0..2]'.c }
      t.column :name, url: true
      t.column :cumulated_absolute_debit_balance, currency: :account_currency, class: "smallcolumns monetary_column debitcolor", default: ''
      t.column :cumulated_absolute_credit_balance, currency: :account_currency, class: "smallcolumns monetary_column creditcolor", default: ''
    end

    list(:centralized_ledger_accounts, model: :accounts, select: [['*']], from: union_subquery, count: 'DISTINCT U.account_number', group: 'U.account_number, U.account_name, U.cumulated_absolute_credit_balance, U.cumulated_absolute_debit_balance, U.account_currency', order: 'U.account_number') do |t|
      t.column :account_number, url: { controller: :general_ledgers, action: :index, current_financial_year: 'params[:current_financial_year]'.c, ledger: 'RECORD.account_number'.c }
      t.column :account_name, url: { controller: :general_ledgers, action: :index, current_financial_year: 'params[:current_financial_year]'.c, ledger: 'RECORD.account_number'.c }
      t.column :cumulated_absolute_debit_balance, currency: :account_currency, class: "smallcolumns monetary_column debitcolor", default: ''
      t.column :cumulated_absolute_credit_balance, currency: :account_currency, class: "smallcolumns monetary_column creditcolor", default: ''
    end

    list(:subledger_journal_entry_items, model: :journal_entry_items, conditions: list_conditions, joins: %i[entry account journal], order: "#{JournalEntryItem.table_name}.printed_on, #{JournalEntryItem.table_name}.id") do |t|
      t.column :printed_on, class: "smallcolumns printed_on_column"
      t.column :journal_name, url: { controller: :journals, id: 'RECORD.journal_id'.c }, label: :journal, class: :mediumcolumns
      t.column :account, url: true, hidden: true, class: :largecolumns
      t.column :account_number, through: :account, label_method: :number, url: { controller: :general_ledgers, account_number: 'RECORD.account.number'.c, current_financial_year: 'params[:current_financial_year]'.c, ledger: 'RECORD.account&.number[0..2]'.c }, hidden: true, class: :mediumcolumns
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true, class: :mediumcolumns
      t.column :entry_number, url: { controller: :journal_entries, id: 'RECORD.entry_id'.c }, class: :smallcolumns
      t.column :continuous_number, hidden: true
      t.column :code, through: :journal, label: :journal, hidden: true, class: :smallcolumns
      t.column :entry_resource_label, url: { controller: 'RECORD&.entry&.resource&.class&.model_name&.plural'.c, id: 'RECORD&.entry&.resource&.id'.c }, label: :entry_resource_label, class: :largecolumns
      t.column :name, class: :entryname
      t.column :reference_number, through: :entry, hidden: true, class: :smallcolumns
      t.column :variant, url: true, hidden: true, class: :smallcolumns
      t.column :letter, class: "smallcolumns letterscolumn"
      t.column :real_debit,  currency: :real_currency, hidden: true, class: "smallcolumns monetary_column"
      t.column :real_credit, currency: :real_currency, hidden: true, class: "smallcolumns monetary_column"
      t.column :debit,  currency: true, class: "smallcolumns monetary_column", default: ''
      t.column :credit, currency: true, class: "smallcolumns monetary_column", default: ''
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true, class: "smallcolumns monetary_column"
      t.column :absolute_credit, currency: :absolute_currency, hidden: true, class: "smallcolumns monetary_column"
    end

    def index
      return redirect_to(controller: :general_ledgers, action: :show, account_number: Account.find_by(number: params[:ledger]).number, current_financial_year: params[:current_financial_year]) if params[:ledger] && Account.find_by(number: params[:ledger])

      ledger_label = :general_ledger.tl

      params[:ledger] ||= 'general_ledger'

      accounts = Account.get_auxiliary_accounts(params[:ledger])
      if accounts.present?
        ledger_label = :subledger_of_accounts_x.tl(account: accounts.first.centralizing_account_name.tl)
        params[:accounts] = accounts.pluck(:number)
      end
      t3e(ledger: ledger_label)

      document_nature = Nomen::DocumentNature.find(:general_ledger)
      key = "#{document_nature.name}-#{Time.zone.now.l(format: '%Y-%m-%d-%H:%M:%S')}"

      respond_to do |format|
        format.html
        format.ods do
          @general_ledger = Account.ledger(params) if params[:period]
          send_data(
            to_ods(@general_ledger).bytes,
            filename: key << '.ods'
          )
        end
        format.csv do
          @general_ledger = Account.ledger(params) if params[:period]
          csv_string = CSV.generate(headers: true) do |csv|
            to_csv(@general_ledger, csv)
          end
          send_data(csv_string, filename: key << '.csv')
        end
        format.xcsv do
          @general_ledger = Account.ledger(params) if params[:period]
          csv_string = CSV.generate(headers: true, col_sep: ';', encoding: 'CP1252') do |csv|
            to_csv(@general_ledger, csv)
          end
          send_data(csv_string, filename: key << '.csv')
        end
        format.pdf do
          template_path = find_open_document_template(:general_ledger)
          @general_ledger = Account.ledger(params) if params[:period]
          raise 'Cannot find template' if template_path.nil?
          general_ledger_printer = GeneralLedgerPrinter.new(general_ledger: @general_ledger,
                                                            document_nature: document_nature,
                                                            key: key,
                                                            template_path: template_path,
                                                            params: params)
          send_file general_ledger_printer.run, type: 'application/pdf', disposition: 'attachment', filename: key << '.pdf'
        end
      end
    end

    def show
      return redirect_to(backend_general_ledgers_path) unless params[:account_number] && account = Account.find_by(number: params[:account_number])

      t3e(account: account.label)

      document_nature = Nomen::DocumentNature.find(:general_ledger)
      key = "#{document_nature.name}-#{Time.zone.now.l(format: '%Y-%m-%d-%H:%M:%S')}"

      conditions_code = '(' + self.class.list_conditions.gsub(/\s*\n\s*/, ';') + ')'

      obj = eval(conditions_code)

      @calculations = JournalEntryItem.joins(%i[entry account journal]).where(obj).pluck("COALESCE(SUM(#{JournalEntryItem.table_name}.absolute_debit), 0) AS cumulated_absolute_debit, COALESCE(SUM(#{JournalEntryItem.table_name}.absolute_credit), 0) AS cumulated_absolute_credit").first
      @calculations << @calculations[0] - @calculations[1]

      respond_to do |format|
        format.html
        format.ods do
          @general_ledger = Account.ledger(params) if params[:period]
          send_data(
            to_ods(@general_ledger).bytes,
            filename: filename << '.ods'
          )
        end
        format.csv do
          @general_ledger = Account.ledger(params) if params[:period]
          csv_string = CSV.generate(headers: true) do |csv|
            to_csv(@general_ledger, csv)
          end
          send_data(csv_string, filename: filename << '.csv')
        end
        format.xcsv do
          @general_ledger = Account.ledger(params) if params[:period]
          csv_string = CSV.generate(headers: true, col_sep: ';', encoding: 'CP1252') do |csv|
            to_csv(@general_ledger, csv)
          end
          send_data(csv_string, filename: filename << '.csv')
        end
        format.pdf do
          template_path = find_open_document_template(:general_ledger)
          @general_ledger = Account.ledger(params) if params[:period]
          raise 'Cannot find template' if template_path.nil?
          general_ledger_printer = GeneralLedgerPrinter.new(general_ledger: @general_ledger,
                                                            document_nature: document_nature,
                                                            key: key,
                                                            template_path: template_path,
                                                            params: params)
          send_file general_ledger_printer.run, type: 'application/pdf', disposition: 'attachment', filename: key << '.pdf'
        end
      end
    end

    def mask_lettered_items
      preference_name = 'backend/general_ledgers'
      preference_name << ".#{params[:context]}" if params[:context]
      preference_name << '.lettered_items.masked'
      current_user.prefer!(preference_name, params[:masked].to_s == 'true', :boolean)
      head :ok
    end

    def mask_draft_items
      preference_name = 'backend/general_ledgers'
      preference_name << ".#{params[:context]}" if params[:context]
      preference_name << '.draft_items.masked'
      current_user.prefer!(preference_name, params[:masked].to_s == 'true', :boolean)
      head :ok
    end

    protected

    def to_csv(general_ledger, csv)
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

      general_ledger.each do |account|
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

    def to_ods(general_ledger)
      require 'rodf'
      output = RODF::Spreadsheet.new

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

          general_ledger.each do |account|
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
  end
end
