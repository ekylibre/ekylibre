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

class Backend::CashTransfersController < BackendController
  manage_restfully :created_on => 'Date.today'.c

  unroll

  list do |t|
    t.column :number, url: true
    t.column :emission_amount,  :currency => :emission_currency
    t.column :name, through: :emission_cash, url: true
    t.column :reception_amount, :currency => :reception_currency
    t.column :name, through: :reception_cash, url: true
    t.column :created_on
    t.column :description
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of cash transfers
  def index
  end

  # Displays details of one cash transfer selected with +params[:id]+
  def show
    return unless @cash_transfer = find_and_check
    t3e @cash_transfer.attributes
  end

end
