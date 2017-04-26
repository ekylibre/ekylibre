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
  class IncomingPaymentsController < Backend::BaseController
    manage_restfully(
      to_bank_at: 'Time.zone.today'.c,
      paid_at: 'Time.zone.today'.c,
      responsible_id: 'current_user.id'.c,
      received: true,
      mode_id: 'params[:mode_id] ? params[:mode_id] : (payer = Entity.find_by(id: params[:entity_id].to_i)) ? payer.incoming_payments.reorder(id: :desc).first.mode_id : nil'.c,
      t3e: {
        payer: 'RECORD.payer.full_name'.c,
        entity: 'RECORD.payer.full_name'.c,
        number: 'RECORD.number'.c
      }
    )

    unroll :number, :amount, :currency, mode: :name, payer: :full_name

    def self.incoming_payments_conditions(_options = {})
      code = search_conditions(incoming_payments: %i[amount bank_check_number number bank_account_number], entities: %i[number full_name]) + "||=[]\n"
      code << "if params[:s] == 'not_received'\n"
      code << "  c[0] += ' AND received=?'\n"
      code << "  c << false\n"
      code << "elsif params[:s] == 'to_deposit_later'\n"
      code << "  c[0] += ' AND to_bank_at > ?'\n"
      code << "  c << Time.zone.today\n"
      code << "elsif params[:s] == 'to_deposit_now'\n"
      code << "  c[0] += ' AND to_bank_at <= ? AND deposit_id IS NULL AND #{IncomingPaymentMode.table_name}.with_deposit'\n"
      code << "  c << Time.zone.now\n"
      # code << "elsif params[:s] == 'unparted'\n"
      # code << "  c[0] += ' AND used_amount != amount'\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: incoming_payments_conditions, joins: :payer, order: { to_bank_at: :desc }) do |t|
      t.action :edit, unless: :deposit?
      t.action :destroy
      t.column :number, url: true
      t.column :payer, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :received, hidden: true
      t.column :deposit, url: true
      t.column :work_name, through: :affair, label: :affair_number, url: { controller: :sale_affairs }
      t.column :bank_statement_number, through: :journal_entry, url: { controller: :bank_statements, id: 'RECORD.journal_entry.bank_statements.first.id'.c }, label: :bank_statement_number
    end
  end
end
