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

class ProductsController < ApplicationController

  list(:components, :model=>:product_components, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :name
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:prices, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :name, :through=>:entity, :url=>true
    t.column :name, :through=>:category, :url=>true
    t.column :pretax_amount
    t.column :amount
    t.column :by_default
    # t.column :range
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :product_id =>['session[:product_id]']}, :line_class=>'RECORD.state', :order=>"updated_at DESC") do |t|
    t.column :name
    # t.column :name, :through=>:origin
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :virtual
    t.column :planned_on
    t.column :moved_on
  end

  list(:stocks, :conditions=>['#{Stock.table_name}.company_id = ? AND #{Stock.table_name}.product_id = ?', ['@current_company.id'], ['session[:product_id]']], :line_class=>'RECORD.state', :order=>"updated_at DESC") do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    #t.column :quantity_max
    #t.column :quantity_min
    #t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
  end

  list(:conditions=>products_conditions) do |t|
    # t.column :number
    t.column :name, :through=>:category, :url=>true
    t.column :name, :url=>true
    t.column :code, :url=>true
    t.column :stockable
    t.column :nature_label
    t.column :label, :through=>:unit
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays details of one product selected with +params[:id]+
  def show
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    t3e @product.attributes
  end

  def new
    @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    if request.post?
      #raise Exception.new params.inspect
      @product = @current_company.products.new(params[:product])
      @product.duration = params[:product][:duration]
      @stock = @current_company.stocks.new(params[:stock])
      # @price = @current_company.prices.new(params[:price])
      ActiveRecord::Base.transaction do
        saved = @product.save
        if @product.stockable and saved
          @stock.product_id = @product.id
          saved = false unless @stock.save
          @product.errors.add_from_record(@stock)
        end
#         if @product.to_sale and saved
#           @price.product_id = @product.id
#           @price.entity_id = @current_company.id
#           saved = false unless @price.save
#           @product.errors.add_from_record(@price)          
#         end
        raise ActiveRecord::Rollback unless saved
        return if save_and_redirect(@product, :saved=>saved)
      end
    else 
      @product = Product.new(:nature=>Product.natures.first[1])
      @stock = Stock.new
#      @price = Price.new
    end
    render_restfully_form
  end

  def create
    @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    if request.post?
      #raise Exception.new params.inspect
      @product = @current_company.products.new(params[:product])
      @product.duration = params[:product][:duration]
      @stock = @current_company.stocks.new(params[:stock])
      # @price = @current_company.prices.new(params[:price])
      ActiveRecord::Base.transaction do
        saved = @product.save
        if @product.stockable and saved
          @stock.product_id = @product.id
          saved = false unless @stock.save
          @product.errors.add_from_record(@stock)
        end
#         if @product.to_sale and saved
#           @price.product_id = @product.id
#           @price.entity_id = @current_company.id
#           saved = false unless @price.save
#           @product.errors.add_from_record(@price)          
#         end
        raise ActiveRecord::Rollback unless saved
        return if save_and_redirect(@product, :saved=>saved)
      end
    else 
      @product = Product.new(:nature=>Product.natures.first[1])
      @stock = Stock.new
#      @price = Price.new
    end
    render_restfully_form
  end

  def destroy
    return unless @product = find_and_check(:product)
    if request.post? or request.delete?
      @product.destroy
    end
    redirect_to_current
  end

  def edit
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    if !@product.stockable
      @stock = Stock.new
    else
      @stock = Stock.find(:first, :conditions=>{:company_id=>@current_company.id ,:product_id=>@product.id} )||Stock.new 
    end
    if request.post?
      saved = false
      ActiveRecord::Base.transaction do
        if saved = @product.update_attributes(params[:product])
          if @stock.id.nil? and params[:product][:stockable] == "1"
            @stock = Stock.new(params[:stock])
            @stock.product_id = @product.id
            @stock.company_id = @current_company.id 
            save = false unless @stock.save
            #raise Exception.new "ghghgh"
          elsif !@stock.id.nil? and @warehouses.size > 1
            save = false unless @stock.add_or_update(params[:stock],@product.id)
          else
            #save = false unless @stock.update_attributes(params[:stock])
            save = true
          end
          @product.errors.add_from_record(@stock)
        end
        raise ActiveRecord::Rollback unless saved  
      end
      return if save_and_redirect(@product, :saved=>saved)
    end
    t3e @product.attributes
    render_restfully_form
  end

  def update
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    if !@product.stockable
      @stock = Stock.new
    else
      @stock = Stock.find(:first, :conditions=>{:company_id=>@current_company.id ,:product_id=>@product.id} )||Stock.new 
    end
    if request.post?
      saved = false
      ActiveRecord::Base.transaction do
        if saved = @product.update_attributes(params[:product])
          if @stock.id.nil? and params[:product][:stockable] == "1"
            @stock = Stock.new(params[:stock])
            @stock.product_id = @product.id
            @stock.company_id = @current_company.id 
            save = false unless @stock.save
            #raise Exception.new "ghghgh"
          elsif !@stock.id.nil? and @warehouses.size > 1
            save = false unless @stock.add_or_update(params[:stock],@product.id)
          else
            #save = false unless @stock.update_attributes(params[:stock])
            save = true
          end
          @product.errors.add_from_record(@stock)
        end
        raise ActiveRecord::Rollback unless saved  
      end
      return if save_and_redirect(@product, :saved=>saved)
    end
    t3e @product.attributes
    render_restfully_form
  end

  # Displays the main page with the list of products
  def index
    #     @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    #     if @warehouses.size < 1
    #       notify(:need_stocks_warehouse_to_create_products, :warning)
    #       redirect_to :action=>:warehouse_create
    #     end
    @key = params[:key]||session[:product_key]||""
    session[:product_key] = @key
    session[:product_active] = true if session[:product_active].nil?
    if request.post?
      session[:product_active] = params[:product_active].nil? ? false : true
      session[:product_category_id] = params[:product].nil? ? 0 : params[:product][:category_id].to_i
    end
  end


  def change_quantities
    @stock = Stock.find(:first, :conditions=>{:warehouse_id=>params[:warehouse_id], :company_id=>@current_company.id, :product_id=>session[:product_id]} ) 
    if @stock.nil?
      @stock = Stock.new(:quantity_min=>1, :quantity_max=>0, :critic_quantity_min=>0)
    end
  end

end
