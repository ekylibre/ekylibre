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

class SaleLinesController < ApplicationController

  def new
    return unless @sale = find_and_check(:sale, params[:sale_id]||session[:current_sale_id])
    @warehouses = @current_company.warehouses
    default_attributes = {:company_id=>@current_company.id, :price_amount=>0.0, :reduction_percent=>@sale.client.max_reduction_percent}
    @sale_line = @sale.lines.new(default_attributes)
    if @current_company.available_prices.size > 0
      # @subscription = Subscription.new(:product_id=>@current_company.available_prices.first.product.id, :company_id=>@current_company.id).compute_period
      @product = @current_company.available_prices.first.product
      @warehouse = @warehouses.first
      session[:current_product_id] = @product.id
      session[:current_warehouse_id] = @warehouse.id
    else
      # @subscription = Subscription.new()
    end
    if @warehouses.empty? 
      notify_warning(:need_warehouse_to_create_sale_line)
      redirect_to :action=>:warehouse_create
      return
    elsif not @sale.draft?
      notify_error(:impossible_to_add_lines)
      redirect_to :action=>:sale, :step=>:products, :id=>@sale.id
      return
    elsif request.post? 
      @sale_line = @sale.lines.build(default_attributes)
      @sale_line.attributes = params[:sale_line]
      @sale_line.warehouse_id = @warehouses[0].id if @warehouses.size == 1

      ActiveRecord::Base.transaction do
        if saved = @sale_line.save
          if @sale_line.subscription?
            @subscription = @sale_line.new_subscription(params[:subscription])
            saved = false unless @subscription.save
            @subscription.errors.add_from_record(@sale_line)
          end
          raise ActiveRecord::Rollback unless saved
        end
        return if save_and_redirect(@sale_line, :url=>{:action=>:sale, :step=>:products, :id=>@sale.id}, :saved=>saved) 
      end
    end
    render_restfully_form
  end

  def create
    return unless @sale = find_and_check(:sale, params[:sale_id]||session[:current_sale_id])
    @warehouses = @current_company.warehouses
    default_attributes = {:company_id=>@current_company.id, :price_amount=>0.0, :reduction_percent=>@sale.client.max_reduction_percent}
    @sale_line = @sale.lines.new(default_attributes)
    if @current_company.available_prices.size > 0
      # @subscription = Subscription.new(:product_id=>@current_company.available_prices.first.product.id, :company_id=>@current_company.id).compute_period
      @product = @current_company.available_prices.first.product
      @warehouse = @warehouses.first
      session[:current_product_id] = @product.id
      session[:current_warehouse_id] = @warehouse.id
    else
      # @subscription = Subscription.new()
    end
    if @warehouses.empty? 
      notify_warning(:need_warehouse_to_create_sale_line)
      redirect_to :controller=>:warehouses, :action=>:new
      return
    elsif not @sale.draft?
      notify_error(:impossible_to_add_lines)
      redirect_to :action=>:sale, :step=>:products, :id=>@sale.id
      return
    elsif request.post? 
      @sale_line = @sale.lines.build(default_attributes)
      @sale_line.attributes = params[:sale_line]
      @sale_line.warehouse_id = @warehouses[0].id if @warehouses.size == 1

      ActiveRecord::Base.transaction do
        if saved = @sale_line.save
          if @sale_line.subscription?
            @subscription = @sale_line.new_subscription(params[:subscription])
            saved = false unless @subscription.save
            @subscription.errors.add_from_record(@sale_line)
          end
          raise ActiveRecord::Rollback unless saved
        end
        return if save_and_redirect(@sale_line, :url=>{:action=>:sale, :step=>:products, :id=>@sale.id}, :saved=>saved) 
      end
    end
    render_restfully_form
  end

  def destroy
    return unless @sale_line = find_and_check(:sale_line)
    if request.post? or request.delete?
      @sale_line.destroy
    end
    redirect_to_current
  end

  def detail
    if request.xhr?
      return unless price = find_and_check(:price)
      @sale = @current_company.sales.find_by_id(params[:sale_id]) if params[:sale_id]
      @sale_line = @current_company.sale_lines.new(:product=>price.product, :price=>price, :price_amount=>0.0, :quantity=>1.0, :unit_id=>price.product.unit_id)
      if @sale
        @sale_line.sale = @sale
        @sale_line.reduction_percent = @sale.client.max_reduction_percent 
      end
      render :partial=>"sale_lines/detail#{'_row' if params[:mode]=='row'}_form"
    else
      redirect_to sales_url
    end
  end

  def edit
    return unless @sale_line = find_and_check(:sale_line)
    @sale = @sale_line.sale 
    @warehouses = @current_company.warehouses
    @product = @sale_line.product
    @subscription = @current_company.subscriptions.find(:first, :conditions=>{:sale_id=>@sale.id}) || Subscription.new
    #raise Exception.new @subscription.inspect
    if request.post?
      @sale_line.attributes = params[:sale_line]
      return if save_and_redirect(@sale_line)
    end
    t3e :product=>@sale_line.product.name
    render_restfully_form
  end

  def update
    return unless @sale_line = find_and_check(:sale_line)
    @sale = @sale_line.sale 
    @warehouses = @current_company.warehouses
    @product = @sale_line.product
    @subscription = @current_company.subscriptions.find(:first, :conditions=>{:sale_id=>@sale.id}) || Subscription.new
    #raise Exception.new @subscription.inspect
    if request.post?
      @sale_line.attributes = params[:sale_line]
      return if save_and_redirect(@sale_line)
    end
    t3e :product=>@sale_line.product.name
    render_restfully_form
  end

end
