# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::BankStatementsController < BackendController
  manage_restfully :started_at => "Cash.find(params[:cash_id]).last_bank_statement.stopped_at+1 rescue (Date.today-1.month-2.days)".c, :stopped_at => "Cash.find(params[:cash_id]).last_bank_statement.stopped_at>>1 rescue (Date.today-2.days)".c, :redirect_to => '{action: :point, :id => "id"}'.c

  unroll

  list(order: {started_at: :desc}) do |t|
    t.column :number, url: true
    t.column :cash,   url: true
    t.column :started_at
    t.column :stopped_at
    t.column :debit,  currency: true
    t.column :credit, currency: true
    t.action :point
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of bank statements
  def index
    cashes = Cash.bank_accounts
    unless cashes.count > 0
      notify(:need_cash_to_record_statements)
      redirect_to new_cash_url
      return
    end
    notify_now(:x_unpointed_journal_entry_items, :count => JournalEntryItem.where("bank_statement_id IS NULL and account_id IN (?)", cashes.map(&:account_id)).count)
  end

  list(:items, model: :journal_entry_items, conditions: {bank_statement_id: 'params[:id]'.c}, order: :entry_id) do |t|
    t.column :journal, url: true
    t.column :entry_number, url: true
    t.column :printed_on
    t.column :name
    t.column :account, url: true
    t.column :debit, currency: true
    t.column :credit, currency: true
  end


  def point
    session[:statement] = params[:id]  if request.get?
    return unless @bank_statement = find_and_check
    if request.post?
      # raise StandardError.new(params[:journal_entry_item].inspect)
      if @bank_statement.point(params[:journal_entry_item].select{|k, v| v[:checked]=="1" and JournalEntryItem.find_by_id(k)}.collect{|k, v| k.to_i})
        redirect_to action: :index
        return
      end
    end
    @journal_entry_items = @bank_statement.eligible_items
    unless @journal_entry_items.size > 0
      notify_warning(:need_entries_to_point)
      redirect_to action: :index
    end
    t3e @bank_statement.attributes, :cash => @bank_statement.cash.name
  end

end
