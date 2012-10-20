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

class PurchaseLinesController < AdminController

  def new
    return unless @purchase = find_and_check(:purchase, params[:purchase_id])
    if Warehouse.count.zero?
      notify_warning(:need_warehouse_to_create_purchase_line)
      redirect_to :action=>:new, :controller=>:warehouses
      return
    elsif not @purchase.draft?
      notify_warning(:impossible_to_add_lines_to_purchase)
      redirect_to :action=>:show, :controller=>:purchases, :step=>:products, :id=>@purchase.id
      return
    end
    @purchase_line = @purchase.lines.new
    @price = Price.new(:pretax_amount=>0.0, :currency => @purchase.currency)
    session[:current_currency] = @price.currency
    t3e @purchase.attributes
    render_restfully_form
  end

  def create
    return unless @purchase = find_and_check(:purchase, params[:purchase_id])
    if Warehouse.count.zero?
      notify_warning(:need_warehouse_to_create_purchase_line)
      redirect_to :action=>:new, :controller=>:warehouses
      return
    elsif not @purchase.draft?
      notify_warning(:impossible_to_add_lines_to_purchase)
      redirect_to :action=>:show, :controller=>:purchases, :step=>:products, :id=>@purchase.id
      return
    end
    return unless product = find_and_check(:product, params[:purchase_line][:product_id].to_i)
    if params[:price]
      price_attrs = params[:price].symbolize_keys.merge(:product_id=>product.id, :entity_id=>@purchase.supplier_id)
      price = Price.find(:first, :conditions=>price_attrs)
      price ||= Price.create!(price_attrs.merge(:active=>true))
      params[:purchase_line][:price_id] = price.id
    end
    @purchase_line = @purchase.lines.new(params[:purchase_line])
    return if save_and_redirect(@purchase_line, :url=>{:controller=>:purchases, :action=>:show, :step=>:products, :id=>@purchase.id})
    t3e @purchase.attributes
    render_restfully_form
  end

  def edit
    return unless @purchase_line = find_and_check(:purchase_line)
    t3e @purchase_line.attributes
    render_restfully_form
  end

  def update
    return unless @purchase_line = find_and_check(:purchase_line)
    return unless product = find_and_check(:product, params[:purchase_line][:product_id].to_i)
    if params[:price]
      price_attrs = params[:price].symbolize_keys.merge(:product_id=>product.id, :entity_id=>@purchase_line.purchase.supplier_id)
      price = Price.find(:first, :conditions=>price_attrs)
      price ||= Price.create!(price_attrs.merge(:active=>true))
      params[:purchase_line][:price_id] = price.id
    end
    if @purchase_line.update_attributes(params[:purchase_line])  
      redirect_to :controller=>:purchases, :action=>:show, :step=>:products, :id=>@purchase_line.purchase_id  
      return
    end
    t3e @purchase_line.attributes
    render_restfully_form
  end

  def destroy
    return unless @purchase_line = find_and_check(:purchase_line)
    @purchase_line.destroy
    redirect_to_current
  end

end
