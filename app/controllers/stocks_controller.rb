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
  manage_restfully

  formize do |f|
    f.field :warehouse, :new=>true, :choices=>:warehouses
    f.field_set(:general) do |s|
      s.field :product, :new=>true, :choices=>:stockable_products
    end
    f.field_set(:product_options, :depend_on=>:product) do |s|
      s.field :unit, :choices=>:units, :new=>{:base=>"product.unit.base"}, :source=>"product", :default=>"product.unit"
      s.field :tracking, :choices=>:trackings, :include_blank=>true, :source=>"product"
      s.field :critic_quantity_min
      s.field :quantity_min
      s.field :quantity_max
    end
  end
        

  def self.stocks_conditions(options={})
    code = ""
    code << "conditions = {} \n"
    code << "conditions[:company_id] = @current_company.id\n"
    code << "conditions[:warehouse_id] = session[:warehouse_id].to_i if session[:warehouse_id].to_i > 0\n"
    code << "conditions\n"
    code
  end

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
    respond_to do |format|
      format.html do
        notify_warning_now(:no_warehouse) if @current_company.warehouses.size.zero?
        notify_now(:no_stocks) if @current_company.stocks.size <= 0
        session[:warehouse_id] = params[:warehouse_id]
      end
      format.pdf { render_print_stocks(params[:established_on]||Date.today) }
    end
  end

end
