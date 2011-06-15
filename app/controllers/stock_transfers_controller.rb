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

class StockTransfersController < ApplicationController
  manage_restfully :nature=>"'transfer'", :planned_on=>"Date.today"

  list(:confirm, :model=>:stock_transfers, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :order=>"planned_on") do |t|
    t.column :text_nature
    t.column :name, :through=>:product
    t.column :quantity, :datatype=>:decimal
    t.column :name, :through=>:warehouse
    t.column :name, :through=>:second_warehouse
    t.column :planned_on, :children=>false
    t.check_box :executed, :value=>'RECORD.planned_on<=Date.today'
  end

  list(:conditions=>moved_conditions(StockTransfer)) do |t|
    t.column :text_nature
    t.column :name, :through=>:product, :url=>true
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:second_warehouse, :url=>true
    t.column :planned_on
    t.column :moved_on
    t.action :confirm, :method=>:post, :if=>'RECORD.moved_on.nil? ', :confirm=>:are_you_sure
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of stock transfers
  def index
  end

  def confirm
    return unless stock_transfer = find_and_check(:stock_transfer)
    stock_transfer.execute if request.post?
    redirect_to :action=>:index, :mode=>:unconfirmed
  end

  def confirm_all
    @stock_transfers = @current_company.stock_transfers.find(:all, :conditions=>{:moved_on=>nil}, :order=>"planned_on ASC")
    
    if request.post?
      transfers = []
      for id, values in params[:stock_transfers_confirm]
        return unless transfer = find_and_check(:stock_transfer, id)
        transfers << transfer if values[:executed].to_i == 1
      end
      for transfer in transfers
        transfer.update_attributes(:moved_on=>Date.today)
      end
      redirect_to confirm_all_stock_transfers_url
    end
  end

end
