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

class CashTransfersController < ApplicationController
  manage_restfully :created_on=>'Date.today'

  list(:conditions=>["#{CashTransfer.table_name}.company_id = ? ", ['@current_company.id']]) do |t|
    t.column :number, :url=>true
    t.column :emitter_amount
    t.column :name, :through=>:emitter_currency
    t.column :name, :through=>:emitter_cash, :url=>true
    t.column :receiver_amount
    t.column :name, :through=>:receiver_currency
    t.column :name, :through=>:receiver_cash, :url=>true
    t.column :created_on
    t.column :comment
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of cash transfers
  def index
  end

  # Displays details of one cash transfer selected with +params[:id]+
  def show
    return unless @cash_transfer = find_and_check(:cash_transfer)
    t3e @cash_transfer.attributes
  end

end
