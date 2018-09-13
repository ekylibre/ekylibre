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
    def self.list_conditions
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit] }, conditions: 'c') + "\n"
      code << ledger_crit('params')
      code << journal_period_crit('params')
      code << account_crit('params')
      code << "c\n"
      code.c
    end

    list(:journal_entry_items, conditions: list_conditions, joins: %i[entry account journal], order: "accounts.number, journal_entries.number, #{JournalEntryItem.table_name}.position") do |t|
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: { controller: :general_ledgers, account_number: 'RECORD.account.number'.c, current_financial_year: 'params[:current_financial_year]'.c, ledger: 'RECORD.account&.centralizing_account&.number'.c }
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :entry_number, url: true
      t.column :continuous_number
      t.column :code, through: :journal, label: :journal
      t.column :printed_on
      t.column :name
      t.column :reference_number, through: :entry
      t.column :variant, url: true, hidden: true
      t.column :letter
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true, hidden: true, on_select: :sum
      t.column :credit, currency: true, hidden: true, on_select: :sum
      t.column :absolute_debit,  currency: :absolute_currency, on_select: :sum
      t.column :absolute_credit, currency: :absolute_currency, on_select: :sum
      t.column :cumulated_absolute_debit,  currency: :absolute_currency, on_select: :sum
      t.column :cumulated_absolute_credit, currency: :absolute_currency, on_select: :sum
    end

    def index
      document_name = human_action_name.to_s
      filename = "#{human_action_name}_#{Time.zone.now.l(format: '%Y%m%d%H%M%S')}"
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
        format.odt do
          @general_ledger = Account.ledger(params) if params[:period]
          send_data to_odt(@general_ledger, document_name, filename, params).generate, type: 'application/vnd.oasis.opendocument.text', disposition: 'attachment', filename: filename << '.odt'
        end
      end
    end

    def show
      return redirect_to(backend_general_ledgers_path) unless params[:account_number] && account = Account.find_by(number: params[:account_number])

      t3e(account: account.label)
      document_name = human_action_name.to_s
      filename = "#{human_action_name}_#{Time.zone.now.l(format: '%Y%m%d%H%M%S')}"
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
        format.odt do
          @general_ledger = Account.ledger(params) if params[:period]
          send_data to_odt(@general_ledger, document_name, filename, params).generate, type: 'application/vnd.oasis.opendocument.text', disposition: 'attachment', filename: filename << '.odt'
        end
      end
    end

    protected

    def to_odt(general_ledger, document_name, filename, params)
      # TODO: add a generic template system path
      report = ODFReport::Report.new(Rails.root.join('config', 'locales', 'fra', 'reporting', 'general_ledger.odt')) do |r|
        # TODO: add a helper with generic metod to implemend header and footer

        data_filters = []
        unless params[:accounts].empty?
          data_filters << Account.human_attribute_name(:account) + ' : ' + params[:accounts]
        end

        if params[:lettering_state]
          content = []
          content << :unlettered.tl if params[:lettering_state].include?('unlettered')
          content << :partially_lettered.tl if params[:lettering_state].include?('partially_lettered')
          content << :lettered.tl if params[:lettering_state].include?('lettered')
          data_filters << :lettering_state.tl + ' : ' + content.to_sentence
        end

        if params[:states].any?
          content = []
          content << :draft.tl if params[:states].include?('draft') && params[:states]['draft'].to_i == 1
          content << :confirmed.tl if params[:states].include?('confirmed') && params[:states]['confirmed'].to_i == 1
          content << :closed.tl if params[:states].include?('closed') && params[:states]['closed'].to_i == 1
          data_filters << :journal_entries_states.tl + ' : ' + content.to_sentence
        end

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address.coordinate

        started_on = params[:period].split('_').first if params[:period]
        stopped_on = params[:period].split('_').last if params[:period]

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILENAME', filename
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'STARTED_ON', started_on.to_date.strftime('%d/%m/%Y') if started_on
        r.add_field 'STOPPED_ON', stopped_on.to_date.strftime('%d/%m/%Y') if stopped_on
        r.add_field 'DATA_FILTERS', data_filters * ' | '

        r.add_section('Section1', general_ledger) do |s|
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

        office_style :right, family: :cell do
          property :paragraph, 'text-align': :right
        end

        office_style :bold, family: :cell do
          property :text, 'font-weight': :bold
        end

        office_style :italic, family: :cell do
          property :text, 'font-style': :italic
        end

        table 'ledger' do
          row do
            cell JournalEntryItem.human_attribute_name(:account_number), style: :head
            cell JournalEntryItem.human_attribute_name(:account_name), style: :head
            cell JournalEntryItem.human_attribute_name(:entry_number), style: :head
            cell JournalEntryItem.human_attribute_name(:printed_on), style: :head
            cell JournalEntryItem.human_attribute_name(:name), style: :head
            cell JournalEntryItem.human_attribute_name(:variant), style: :head
            cell JournalEntryItem.human_attribute_name(:journal), style: :head
            cell JournalEntryItem.human_attribute_name(:letter), style: :head
            cell JournalEntry.human_attribute_name(:debit), style: :head
            cell JournalEntry.human_attribute_name(:credit), style: :head
            cell JournalEntry.human_attribute_name(:balance), style: :head
          end

          general_ledger.each do |account|
            account.each do |item|
              if item[0] == 'header'
                row do
                  cell item[1], style: :head
                  cell item[2], style: :head
                end
              elsif item[0] == 'body'
                row do
                  cell item[1]
                  cell item[2]
                  cell item[3]
                  cell item[4]
                  cell item[5]
                  cell item[6]
                  cell item[7]
                  cell item[8]
                  cell item[9]
                  cell item[10]
                  cell item[11]
                end
              elsif item[0] == 'footer'
                row do
                  cell ''
                  cell item[2]
                  cell ''
                  cell ''
                  cell ''
                  cell ''
                  cell ''
                  cell :subtotal.tl(name: item[1]).l, style: :right
                  cell item[12], style: :bold
                  cell item[13], style: :bold
                end
              end
            end
          end
        end
      end
      output
    end
  end
end
