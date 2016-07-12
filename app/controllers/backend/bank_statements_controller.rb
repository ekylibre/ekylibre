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
  class BankStatementsController < Backend::BaseController
    manage_restfully(
      started_on: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_on + 1 rescue (Time.zone.today-1.month-2.days)'.c,
      stopped_on: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_on >> 1 rescue (Time.zone.today-2.days)'.c,
      redirect_to: "{action: :reconciliation, id: 'id'.c}".c
    )

    unroll

    list(order: { started_on: :desc }) do |t|
      t.action :reconciliation
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :cash,   url: true
      t.column :started_on
      t.column :stopped_on
      t.column :debit,  currency: true
      t.column :credit, currency: true
    end

    # Displays the main page with the list of bank statements
    def index
      redirect_to backend_cashes_path
    end

    list(:items, model: :bank_statement_items, conditions: { bank_statement_id: 'params[:id]'.c }, order: :id) do |t|
      t.column :journal, url: true
      t.column :transfered_on
      t.column :name
      t.column :account, url: true
      t.column :debit, currency: :currency
      t.column :credit, currency: :currency
    end

    def import
      @cash = Cash.find_by(id: params[:cash_id])
      if request.post?
        file = params[:upload]
        @import = OfxImport.new(file, @cash)
        if @import.run
          redirect_to action: :show, id: @import.bank_statement.id
        elsif @import.recoverable?
          @cash = @import.cash
          @bank_statement = @import.bank_statement
          @bank_statement.errors.add(:cash, :no_cash_match_ofx) unless @cash.valid?
          render :new
        end
      end
    end

    def reconciliation
      return unless @bank_statement = find_and_check
      if request.post?
        @bank_statement.attributes = permitted_params
        items = (params[:items] || {}).values
        journal_entry_items = (params[:journal_entry_items] || {})
        if @bank_statement.save_with_items(items)
          journal_entry_items.each do |journal_entry_item_id, attributes|
            letter = attributes[:bank_statement_letter].presence
            JournalEntryItem.where(id: journal_entry_item_id).update_all(
              bank_statement_id: @bank_statement.id,
              bank_statement_letter: letter
            )
          end
          redirect_to params[:redirect] || { action: :show, id: @bank_statement.id }
          return
        end
      end
      bank_statement_items = @bank_statement.items.order('ABS(debit-credit)')
      journal_entry_items = @bank_statement.eligible_journal_entry_items.order('ABS(real_debit-real_credit)')
      unless journal_entry_items.any?
        notify_error :need_entries_to_reconciliate
        redirect_to params[:redirect] || { action: :show, id: @bank_statement.id }
        return
      end
      @items = bank_statement_items + journal_entry_items
      @items_grouped_by_date = @items.group_by do |item|
        BankStatementItem === item ? item.transfered_on : item.printed_on
      end.sort
      t3e @bank_statement, cash: @bank_statement.cash_name, started_on: @bank_statement.started_on, stopped_on: @bank_statement.stopped_on
    end
  end
end
