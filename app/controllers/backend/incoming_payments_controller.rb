# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
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

class Backend::IncomingPaymentsController < BackendController
  manage_restfully :to_bank_on => "Date.today", :paid_on => "Date.today", :responsible_id => "current_user.id"

  unroll_all

  def self.incoming_payments_conditions(options={})
    code = search_conditions(:incoming_payments, :incoming_payments => [:amount, :bank_check_number, :number, :bank_account_number], :entities => [:code, :full_name])+"||=[]\n"
    code << "if session[:incoming_payment_state] == 'unreceived'\n"
    code << "  c[0] += ' AND received=?'\n"
    code << "  c << false\n"
    code << "elsif session[:incoming_payment_state] == 'waiting'\n"
    code << "  c[0] += ' AND to_bank_on > ?'\n"
    code << "  c << Date.today\n"
    code << "elsif session[:incoming_payment_state] == 'undeposited'\n"
    code << "  c[0] += ' AND deposit_id IS NULL AND #{IncomingPaymentMode.table_name}.with_deposit'\n"
    # code << "elsif session[:incoming_payment_state] == 'unparted'\n"
    # code << "  c[0] += ' AND used_amount != amount'\n"
    code << "end\n"
    code << "c\n"
    return code
  end

  list(:conditions => incoming_payments_conditions, :joins => :payer, :order => "to_bank_on DESC") do |t|
    t.column :number, :url => true
    t.column :full_name, :through => :payer, :url => true
    t.column :paid_on
    t.column :amount, :currency => true, :url => true
    t.column :name, :through => :mode
    t.column :bank_check_number
    t.column :to_bank_on
    t.column :number, :through => :deposit, :url => true
    t.action :edit, :if => "RECORD.deposit.nil\?"
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of incoming payments
  def index
    session[:incoming_payment_state] = params[:s] || "all"
    session[:incoming_payment_key]   = params[:q]
  end

  # list(:sales, :conditions => ["#{Sale.table_name}.id IN (SELECT expense_id FROM #{IncomingPaymentUse.table_name} WHERE payment_id=? AND expense_type=?)", ['session[:current_incoming_payment_id]'], Sale.name], :line_class => 'RECORD.tags') do |t|
  #   t.column :number, :url => true
  #   t.column :description, :through => :client, :url => true
  #   t.column :created_on
  #   t.column :pretax_amount
  #   t.column :amount
  # end

  # Displays details of one incoming payment selected with +params[:id]+
  def show
    return unless @incoming_payment = find_and_check(:incoming_payment)
    session[:current_incoming_payment_id] = @incoming_payment.id
    t3e :number => @incoming_payment.number, :entity => @incoming_payment.payer.full_name
  end

end
