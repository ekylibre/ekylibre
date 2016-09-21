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
  class OutgoingPaymentListsController < Backend::BaseController
    manage_restfully

    list do |t|
      t.column :number, url: true
      t.column :created_at
      t.column :mode, url: { controller: '/backend/outgoing_payment_modes', id: 'RECORD.mode.id'.c }, label_method: :mode_name
      t.column :payments_count, datatype: :integer
    end

    list(:payments, model: 'OutgoingPayment', conditions: { list_id: 'params[:id]'.c }) do |t|
      t.column :number, url: true
      t.column :payee, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :work_name, through: :affair, label: :affair_number, url: true
      t.column :deal_work_name, through: :affair, label: :purchase_number, url: { controller: :purchases, id: 'RECORD.affair.deals_of_type(Purchase).first.id'.c }
      t.column :main_bank_statement_number, through: :journal_entry, label: :bank_statement_number, url: { controller: :bank_statements, id: 'RECORD.journal_entry.bank_statement.first.id'.c }
    end

  end
end
