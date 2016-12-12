# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
  class JournalEntryItemsController < Backend::BaseController
    unroll :entry_number, :name, :real_debit, :real_credit, :currency, account: :number

    def self.journal_entry_items_conditions
      code = ''
      code << search_conditions + ';'
      code << "if params[:tax_declaration_item_id]\n"
      # code << "  c[0] += ' AND (#{JournalEntry.table_name}.id IN (SELECT entry_id FROM #{JournalEntryItem.table_name} WHERE tax_declaration_item_id=?))'\n"
      code << "  c[0] += ' AND tax_declaration_item_id = ?'\n"
      code << "  c << params[:tax_declaration_item_id]\n"
      code << "end\n"
      code << "unless params[:period].blank? or params[:period]='all'\n"
      code << "  c[0] += ' AND id IN (SELECT account_id FROM #{JournalEntryItem.table_name} AS jel JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id) WHERE '+JournalEntry.period_condition(params[:period], params[:started_on], params[:stopped_on], 'je')+')'\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: journal_entry_items_conditions, joins: :entry, line_class: "(RECORD.position==1 ? 'first-item' : '') + (RECORD.entry_balanced? ? '' : ' error')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
      t.column :entry_number, url: true
      t.column :printed_on, through: :entry, datatype: :date
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :name
      t.column :state_label
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :number, through: :bank_statement, label: :bank_statement_number, url: true, hidden: true
      t.column :pretax_amount, currency: true
      t.column :tax, url: true
    end

    def index; end

    def new
      @journal_entry_item = JournalEntryItem.new
      @journal_entry_item.name = params[:name] if params[:name]
      if params['entry-real-debit'] && params['entry-real-credit']
        debit = params['entry-real-debit'].to_f
        credit = params['entry-real-credit'].to_f
        if debit > credit
          @journal_entry_item.real_credit = debit - credit
        else
          @journal_entry_item.real_debit = credit - debit
        end
      end
      @real_rate = params['journal_entry_real_currency_rate']
      @real_rate &&= @real_rate.to_d
      if params[:journal_id] && @journal = Journal.find_by(id: params[:journal_id])
        if @journal.cashes.count == 1
          @journal_entry_item.account = @journal.cashes.first.account
        end
      end
      params[:printed_on] = params[:printed_on] =~ /\d\d\d\d-\d\d-\d\d/ ? params[:printed_on].to_date : nil
      if params[:printed_on]
        @financial_year = FinancialYear.at(params[:printed_on])
      end
      if request.xhr?
        render partial: 'backend/journal_entry_items/row_form', object: @journal_entry_item
      else
        redirect_to_back
      end
    end

    def show
      if @journal_entry_item = JournalEntryItem.find_by(id: params[:id])
        redirect_to backend_journal_entry_path(@journal_entry_item.entry_id)
      else
        redirect_to backend_root_path
      end
    end
  end
end
