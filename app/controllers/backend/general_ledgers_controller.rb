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
      code << journal_period_crit('params')
      code << journal_entries_states_crit('params')
      code << accounts_range_crit('params')
      code << journals_crit('params')
      code << journal_letter_crit('params')
      code << amount_range_crit('params')
      code << "c\n"
      code.c
    end

    list(:journal_entry_items, conditions: list_conditions, joins: %i[entry account], order: "accounts.number, journal_entries.number, #{JournalEntryItem.table_name}.position") do |t|
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :entry_number, url: true
      t.column :printed_on
      t.column :name
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

    def show
      filename = "#{human_action_name} #{Time.zone.now.l(format: '%Y-%m-%d')}"
      @general_ledger = Account.ledger(params[:started_on], params[:stopped_on]) if params[:period]
      respond_to do |format|
        format.html
        format.ods do
          send_data(
            to_ods(@general_ledger).bytes,
            filename: filename << '.ods'
          )
        end
        format.csv do
          csv_string = CSV.generate(headers: true) do |csv|
            to_csv(@general_ledger, csv)
          end
          send_data(csv_string, filename: filename << '.csv')
        end
        format.xcsv do
          csv_string = CSV.generate(headers: true, col_sep: ';', encoding: 'CP1252') do |csv|
            to_csv(@general_ledger, csv)
          end
          send_data(csv_string, filename: filename << '.csv')
        end
        format.odt do
          send_data to_odt(@general_ledger, filename, params[:period]).generate, type: 'application/vnd.oasis.opendocument.text', disposition: 'attachment', filename: filename << '.odt'
        end
      end
    end
    
    protected

    def to_odt(general_ledger, filename, period)
      # TODO: add a generic template system path
      report = ODFReport::Report.new(Rails.root.join('config', 'locales', 'fra', 'reporting', 'general_ledger.odt')) do |r|
        # TODO: add a helper with generic metod to implemend header and footer

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address.coordinate

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'FILE_NAME', filename
        r.add_field 'PERIOD', period

        r.add_table('Tableau2', general_ledger, header: false) do |t|
          t.add_column(:a) { |item| item[0] }
          t.add_column(:b) do |item|
            Account.find(item[1]).name if item[1].to_i > 0
          end
          t.add_column(:debit) { |item| item[2].to_f }
          t.add_column(:credit) { |item| item[3].to_f }
          t.add_column(:balance) { |item| item[4].to_f }
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

        table "ledger" do
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
              if item[0] == "header"
                row do
                  cell item[1], style: :head
                  cell item[2], style: :head
                end
              elsif item[0] == "body"
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
              elsif item[0] == "footer"
                row do
                  cell ""
                  cell item[2]
                  cell ""
                  cell ""
                  cell ""
                  cell ""
                  cell ""
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
