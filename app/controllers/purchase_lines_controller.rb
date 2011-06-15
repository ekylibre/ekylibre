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

class PurchaseLinesController < ApplicationController

  def new
    return unless @purchase = find_and_check(:purchase, params[:purchase_id])
    if @current_company.warehouses.size <= 0
      notify(:need_warehouse_to_create_purchase_line, :warning)
      redirect_to :action=>:warehouse_create
      return
    elsif not @purchase.draft?
      notify(:impossible_to_add_lines_to_purchase, :warning)
      redirect_to :action=>:purchase, :step=>:products, :id=>@purchase.id
      return
    end
    if request.post?
      return unless product = find_and_check(:product, params[:purchase_line][:product_id].to_i)
      price = @current_company.prices.find(:first, :conditions=>{:product_id=>product.id, :entity_id=>@purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount].to_f, :tax_id=>params[:price][:tax_id].to_i})
      price = product.prices.create!(:entity_id=>@purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount], :tax_id=>params[:price][:tax_id].to_i, :active=>true) if price.nil?
      params[:purchase_line][:price_id] = price.id
      @purchase_line = @purchase.lines.new(params[:purchase_line])
      return if save_and_redirect(@purchase_line, :url=>{:action=>:purchase, :step=>:products, :id=>@purchase.id})
    else
      @purchase_line = @purchase.lines.new
      @price = Price.new(:pretax_amount=>0.0)
    end
    t3e @purchase.attributes
    render_restfully_form
  end

  def create
    return unless @purchase = find_and_check(:purchase, params[:purchase_id])
    if @current_company.warehouses.size <= 0
      notify(:need_warehouse_to_create_purchase_line, :warning)
      redirect_to :action=>:warehouse_create
      return
    elsif not @purchase.draft?
      notify(:impossible_to_add_lines_to_purchase, :warning)
      redirect_to :action=>:purchase, :step=>:products, :id=>@purchase.id
      return
    end
    if request.post?
      return unless product = find_and_check(:product, params[:purchase_line][:product_id].to_i)
      price = @current_company.prices.find(:first, :conditions=>{:product_id=>product.id, :entity_id=>@purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount].to_f, :tax_id=>params[:price][:tax_id].to_i})
      price = product.prices.create!(:entity_id=>@purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount], :tax_id=>params[:price][:tax_id].to_i, :active=>true) if price.nil?
      params[:purchase_line][:price_id] = price.id
      @purchase_line = @purchase.lines.new(params[:purchase_line])
      return if save_and_redirect(@purchase_line, :url=>{:action=>:purchase, :step=>:products, :id=>@purchase.id})
    else
      @purchase_line = @purchase.lines.new
      @price = Price.new(:pretax_amount=>0.0)
    end
    t3e @purchase.attributes
    render_restfully_form
  end

  def destroy
    return unless @purchase_line = find_and_check(:purchase_line)
    if request.post? or request.delete?
      @purchase_line.destroy
    end
    redirect_to_current
  end

  def edit
    return unless @purchase_line = find_and_check(:purchase_line)
    if request.post?
      return unless product = find_and_check(:product, params[:purchase_line][:product_id].to_i)
      price = @current_company.prices.find(:first, :conditions=>{:product_id=>product.id, :entity_id=>@purchase_line.purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount].to_f, :tax_id=>params[:price][:tax_id].to_i})
      price = product.prices.create!(:entity_id=>@purchase_line.purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount], :tax_id=>params[:price][:tax_id].to_i, :active=>true) if price.nil?
      params[:purchase_line][:price_id] = price.id
      if @purchase_line.update_attributes(params[:purchase_line])  
        redirect_to :action=>:purchase, :step=>:products, :id=>@purchase_line.purchase_id  
      end
    end
    t3e @purchase_line.attributes
    render_restfully_form
  end

  def update
    return unless @purchase_line = find_and_check(:purchase_line)
    if request.post?
      return unless product = find_and_check(:product, params[:purchase_line][:product_id].to_i)
      price = @current_company.prices.find(:first, :conditions=>{:product_id=>product.id, :entity_id=>@purchase_line.purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount].to_f, :tax_id=>params[:price][:tax_id].to_i})
      price = product.prices.create!(:entity_id=>@purchase_line.purchase.supplier_id, :pretax_amount=>params[:price][:pretax_amount], :tax_id=>params[:price][:tax_id].to_i, :active=>true) if price.nil?
      params[:purchase_line][:price_id] = price.id
      if @purchase_line.update_attributes(params[:purchase_line])  
        redirect_to :action=>:purchase, :step=>:products, :id=>@purchase_line.purchase_id  
      end
    end
    t3e @purchase_line.attributes
    render_restfully_form
  end

end
