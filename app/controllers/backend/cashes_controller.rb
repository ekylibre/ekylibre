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
  class CashesController < Backend::BaseController
    manage_restfully mode: 'Cash.mode.default_value'.c, currency: 'Preference[:currency]'.c, nature: 'Cash.nature.default_value'.c, t3e: { nature: 'RECORD.nature.l'.c }

    unroll

    list(order: :name) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :nature
      t.column :currency
      t.column :country
      t.column :main_account, url: true
      t.column :suspense_account, url: true
      t.column :journal, url: true
      t.column :last_bank_statement_stopped_on, datatype: :date, label: :last_bank_statement_stopped_on
      t.column :provider_vendor, label_method: 'provider_vendor&.capitalize', hidden: true
    end

    list(:bank_statements, conditions: { cash_id: 'params[:id]'.c }, order: { started_on: :desc }) do |t|
      t.action :edit
      t.action :reconciliation, url: { controller: '/backend/bank_reconciliation/items', action: :index, bank_statement_id: 'r.id'.c }
      t.action :destroy
      t.action :new, on: :none, url: { cash_id: 'params[:id]'.c }
      t.action :edit_interval, on: :none, url: { cash_id: 'params[:id]'.c }
      t.column :number, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :debit, currency: true
      t.column :credit, currency: true
      t.column :remaining_items_to_reconcile, label: :remaining_items_to_reconcile
      t.column :remaining_amount_to_reconcile, currency: true, label: :remaining_amount_to_reconcile
    end

    list(:deposits, conditions: { cash_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, url: true
      t.column :created_at
      t.column :payments_count
      t.column :amount, currency: true
      t.column :mode
      t.column :description
    end

    list(:sessions, model: :cash_session, conditions: { cash_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number
      t.column :started_at
      t.column :stopped_at
      t.column :expected_stop_amount, currency: true
      t.column :noticed_start_amount, currency: true
      t.column :noticed_stop_amount, currency: true
    end
  end
end
