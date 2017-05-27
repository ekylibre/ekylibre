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
      t.column :transfered_on
      t.column :name
      t.column :memo
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
      bank_statement_items = @bank_statement.items.order('ABS(debit-credit)')
      @period_start = @bank_statement.started_on - 20.days
      @period_end   = @bank_statement.stopped_on + 20.days
      @period_start = Date.strptime(params[:period_start], '%Y-%m-%d') if params[:period_start]
      @period_end   = Date.strptime(params[:period_end], '%Y-%m-%d') if params[:period_end]
      journal_entry_items = @bank_statement.eligible_journal_entry_items.between(@period_start, @period_end).order('ABS(real_debit-real_credit)')
      unless journal_entry_items.any?
        notify_error :need_entries_to_reconciliate
        redirect_to params[:redirect] || { action: :show, id: @bank_statement.id }
        return
      end
      bank_statement_items.each do |bank_item|
        next if bank_item.letter
        similar_bank = bank_statement_items.where(bank_item.attributes.slice('transfered_on', 'credit', 'debit'))
        next unless similar_bank.count(:id) == 1
        similar_journal = journal_entry_items.where(
          printed_on: bank_item.transfered_on,
          credit: bank_item.debit,
          debit: bank_item.credit,
          bank_statement_letter: nil
        )
        next unless similar_journal.count(:id) == 1
        letter_lines(similar_bank, similar_journal)
      end
      bank_statement_items.reload
      @items = bank_statement_items + journal_entry_items
      @items_grouped_by_date = @items.group_by do |item|
        BankStatementItem === item ? item.transfered_on : item.printed_on
      end.sort
      t3e @bank_statement, cash: @bank_statement.cash_name, started_on: @bank_statement.started_on, stopped_on: @bank_statement.stopped_on
    end

    def letter
      return head :bad_request unless @bank_statement = find_and_check

      bank_statement_items = params[:bank_statement_items] ? BankStatementItem.where(id: params[:bank_statement_items]) : BankStatementItem.none
      journal_entry_items  = params[:journal_entry_items]  ? JournalEntryItem.where(id: params[:journal_entry_items])   : JournalEntryItem.none

      new_letter = letter_lines(bank_statement_items, journal_entry_items)
      return head(:bad_request) unless new_letter

      respond_to do |format|
        format.json {  render json: { letter: new_letter } }
      end
    end

    def unletter
      return head :bad_request unless @bank_statement = find_and_check

      letter = params[:letter]
      JournalEntryItem
        .pointed_by(@bank_statement)
        .where(bank_statement_letter: letter)
        .update_all(bank_statement_letter: nil, bank_statement_id: nil)
      @bank_statement
        .items
        .where(letter: letter)
        .update_all(letter: nil)

      respond_to do |format|
        format.json {  render json: { letter: letter } }
      end
    end

    private

    def letter_lines(bank_items, journal_items)
      bank_statement = @bank_statement || bank_items.first.bank_statement
      bank_statement.letter_items(bank_items, journal_items) || false
    end
  end
end
