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
  class OutgoingPaymentsController < Backend::BaseController
    manage_restfully to_bank_at: 'Time.zone.today'.c, paid_at: 'Time.zone.today'.c, responsible_id: 'current_user.id'.c, amount: 'params[:amount].to_f'.c, t3e: { payee: 'RECORD.payee.full_name'.c }
    manage_restfully_attachments

    unroll :amount, :bank_check_number, :number, :currency, mode: :name, payee: :full_name

    def self.outgoing_payments_conditions(_options = {})
      code = search_conditions(outgoing_payments: [:amount, :bank_check_number, :number], entities: [:number, :full_name]) + " ||= []\n"
      code << "if params[:s] == 'not_delivered'\n"
      code << "  c[0] += ' AND delivered = ?'\n"
      code << "  c << false\n"
      # code << "elsif params[:s] == 'waiting'\n"
      # code << "  c[0] += ' AND to_bank_at > ?'\n"
      # code << "  c << Time.zone.today\n"
      # code << "elsif params[:s] == 'not_closed'\n"
      # code << "  c[0] += ' AND used_amount != amount'\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: outgoing_payments_conditions, joins: :payee, order: { to_bank_at: :desc }) do |t| # , :line_class => "(RECORD.used_amount.zero? ? 'critic' : RECORD.unused_amount>0 ? 'warning' : '')"
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :payee, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :delivered, hidden: true
      t.column :work_name, through: :affair, label: :affair_number, url: true
      t.column :main_bank_statement_number, through: :journal_entry, label: :bank_statement_number, url: { controller: :bank_statements, id: 'RECORD.journal_entry.bank_statement.first.id'.c }
    end
  end
end
