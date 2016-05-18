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
      started_at: 'Cash.find(params[:cash_id]).last_bank_statement.stopped_at+1 rescue (Time.zone.today-1.month-2.days)'.c,
      stopped_at: "Cash.find(params[:cash_id]).last_bank_statement.stopped_at>>1 rescue (Time.zone.today-2.days)".c
    )

    unroll

    list(order: { started_at: :desc }) do |t|
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
      redirect_to backend_cashes_path
    end

    list(:items, model: :bank_statement_items, conditions: { bank_statement_id: "params[:id]".c }, order: :id) do |t|
      t.column :journal, url: true
      t.column :transfered_on
      t.column :name
      t.column :account, url: true
      t.column :debit, currency: :currency
      t.column :credit, currency: :currency
    end
  end
end
