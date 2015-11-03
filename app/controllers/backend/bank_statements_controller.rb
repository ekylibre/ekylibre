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

class Backend::BankStatementsController < Backend::BaseController
  manage_restfully(
    started_at: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_at+1 rescue (Time.zone.today-1.month-2.days)'.c,
    stopped_at: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_at>>1 rescue (Time.zone.today-2.days)'.c,
    redirect_to: '{action: :point, id: "id".c}'.c
  )

  manage_restfully_attachments

  unroll

  list(order: { started_at: :desc }) do |t|
    t.action :point
    t.action :edit
    t.action :destroy
    t.column :number, url: true
    t.column :cash,   url: true
    t.column :started_at
    t.column :stopped_at
    t.column :debit,  currency: true
    t.column :credit, currency: true
  end

  # Displays the main page with the list of bank statements
  def index
    redirect_to backend_cashes_url
  end

  list(:items, model: :journal_entry_items, conditions: { bank_statement_id: 'params[:id]'.c }, order: :entry_id) do |t|
    t.column :journal, url: true
    t.column :entry_number, url: true
    t.column :printed_on
    t.column :name
    t.column :account, url: true
    t.column :real_debit, currency: :real_currency
    t.column :real_credit, currency: :real_currency
  end

  def point
    return unless @bank_statement = find_and_check
    if request.post?
      params[:journal_entry_items] ||= {}
      pointed = params[:journal_entry_items].select do |k, v|
        v[:checked].to_i > 0 && JournalEntryItem.find_by(id: k)
      end
      if @bank_statement.point(pointed.collect { |k, _v| k.to_i })
        redirect_to params[:redirect] || { action: :show, id: @bank_statement.id }
        return
      end
    end
    @journal_entry_items = @bank_statement.eligible_items
    unless @journal_entry_items.any?
      notify_warning(:need_entries_to_point)
      redirect_to params[:redirect] || { action: :show, id: @bank_statement.id }
      return
    end
    t3e @bank_statement, cash: @bank_statement.cash_name
  end
end
