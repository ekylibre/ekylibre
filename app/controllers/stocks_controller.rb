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

class StocksController < ApplicationController

  list(:conditions=>stocks_conditions, :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:warehouse,:url=>true
    t.column :name, :through=>:product,:url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity, :precision=>3
    t.column :quantity, :precision=>3
    t.column :label, :through=>:unit
  end

  # Displays the main page with the list of stocks
  def index
    @warehouses = @current_company.warehouses
    if @warehouses.size == 0
      notify(:no_warehouse, :warning)
      redirect_to :action=>:warehouse_create
    else
      session[:warehouse_id] = params[:warehouse_id]
    end
    notify(:no_stocks, :now) if @current_company.stocks.size <= 0
  end

end
