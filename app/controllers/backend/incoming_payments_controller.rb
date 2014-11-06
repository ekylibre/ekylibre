# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::IncomingPaymentsController < BackendController
  manage_restfully to_bank_at: "Date.today".c, paid_at: "Date.today".c, responsible_id: "current_user.id".c, mode_id: "params[:mode_id] ? params[:mode_id] : (payer = Entity.find_by(id: params[:entity_id].to_i)) ? payer.incoming_payments.reorder(id: :desc).first.mode_id : nil".c, t3e: {payer: "RECORD.payer.full_name".c, entity: "RECORD.payer.full_name".c , number: "RECORD.number".c}

  unroll

  def self.incoming_payments_conditions(options={})
    code = search_conditions(:incoming_payments => [:amount, :bank_check_number, :number, :bank_account_number], :entities => [:number, :full_name])+"||=[]\n"
    code << "if params[:s] == 'unreceived'\n"
    code << "  c[0] += ' AND received=?'\n"
    code << "  c << false\n"
    code << "elsif params[:s] == 'waiting'\n"
    code << "  c[0] += ' AND to_bank_at > ?'\n"
    code << "  c << Date.today\n"
    code << "elsif params[:s] == 'undeposited'\n"
    code << "  c[0] += ' AND deposit_id IS NULL AND #{IncomingPaymentMode.table_name}.with_deposit'\n"
    # code << "elsif params[:s] == 'unparted'\n"
    # code << "  c[0] += ' AND used_amount != amount'\n"
    code << "end\n"
    code << "c\n"
    return code.c
  end

  list(conditions: incoming_payments_conditions, joins: :payer, order: {to_bank_at: :desc}) do |t|
    t.column :number, url: true
    t.column :payer, url: true
    t.column :paid_at
    t.column :amount, currency: true, url: true
    t.column :mode
    t.column :bank_check_number
    t.column :to_bank_at
    t.column :deposit, url: true
    t.action :edit, :unless => :deposit?
    t.action :destroy, if: :destroyable?
  end

end
