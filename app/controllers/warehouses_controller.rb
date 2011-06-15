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

class WarehousesController < ApplicationController
  manage_restfully :reservoir=>"params[:reservoir]"

  list(:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :warehouse_id=>['session[:current_warehouse_id]']}) do |t|
    t.column :name
    t.column :planned_on
    t.column :moved_on
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product, :url=>true
    t.column :virtual
    t.action :edit, :if=>'RECORD.generated != true'
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete,:if=>'RECORD.generated != true' 
  end

  list(:stocks, :conditions=>{:company_id=>['@current_company.id'], :warehouse_id=>['session[:current_warehouse_id]']}, :order=>"quantity DESC") do |t|
    t.column :name, :through=>:product,:url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :weight, :through=>:product, :label=>:column
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
  end

  list(:conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name, :url=>true
    t.column :comment
    t.column :name, :through=>:establishment
    t.column :name, :through=>:parent, :url=>true
    t.column :reservoir
    #t.action :edit, :mode=>:reservoir, :if=>'RECORD.reservoir == true'
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays details of one warehouse selected with +params[:id]+
  def show
    return unless @warehouse = find_and_check(:warehouse)
    session[:current_warehouse_id] = @warehouse.id
    t3e @warehouse.attributes
  end

  # Displays the main page with the list of warehouses
  def index
    unless @current_company.warehouses.size>0
      notify(:need_warehouse_to_record_stock_moves)
      redirect_to :action=>:warehouse_create
      return
    end
  end

end
