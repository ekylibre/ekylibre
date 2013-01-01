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

class ProductsController < AdminController
  unroll
  unroll :availables
  unroll :stockables

  # management -> products_conditions
  def self.products_conditions(options={})
    code = ""
    code = light_search_conditions(:products=>[:number, :code, :code2, :name, :catalog_name, :description, :catalog_description, :ean13])+"\n"
    code += "if session[:product_state] == 'active'\n"
    code += "  c[0] += ' AND active = ?'\n"
    code += "  c << true\n"
    code += "elsif session[:product_state] == 'inactive'\n"
    code += "  c[0] += ' AND active = ?'\n"
    code += "  c << false\n"
    code += "end\n"
    code += "if session[:product_category_id].to_i > 0\n"
    code += "  c[0] += ' AND category_id = ?'\n"
    code += "  c << session[:product_category_id].to_i\n"
    code += "end\n"
    code += "c\n"
    code
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
    t.action :destroy
  end

  # Displays the main page with the list of products
  def index
    session[:product_state] = params[:s]||"all"
    session[:product_category_id] = params[:category_id].to_i
  end


  list(:components, :model=>:product_components, :conditions=>{:product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :quantity
    t.column :label, :through=>[:component, :unit]
    t.column :name, :through=>:component
    t.action :edit
    t.action :destroy
  end

  list(:prices, :conditions=>{:product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :name, :through=>:entity, :url=>true
    t.column :name, :through=>:category, :url=>true
    t.column :pretax_amount, :currency => true
    t.column :amount, :currency => true
    t.column :by_default
    # t.column :range
    t.action :edit
    t.action :destroy
  end

  list(:stock_moves, :conditions=>{:product_id =>['session[:product_id]']}, :line_class=>'RECORD.state', :order=>"updated_at DESC") do |t|
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

  list(:stocks, :conditions=>['#{Stock.table_name}.product_id = ?', ['session[:product_id]']], :line_class=>'RECORD.state', :order=>"updated_at DESC") do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    #t.column :quantity_max
    #t.column :quantity_min
    #t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
  end

  # Displays details of one product selected with +params[:id]+
  def show
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    t3e @product.attributes
  end

  def new
    @product = Product.new(:nature=>Product.natures.first[1])
    @stock = Stock.new
    render_restfully_form
  end

  def create
    @product = Product.new(params[:product])
    @product.duration = params[:product][:duration]
    @stock = Stock.new(params[:stock])
    ActiveRecord::Base.transaction do
      saved = @product.save
      if @product.stockable and saved
        @stock.product_id = @product.id
        saved = false unless @stock.save
        @product.errors.add_from_record(@stock)
      end
      raise ActiveRecord::Rollback unless saved
      return if save_and_redirect(@product, :saved=>saved)
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
    @stock = @product.default_stock || Stock.new
    t3e @product.attributes
    render_restfully_form
  end

  def update
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    @stock = @product.default_stock || Stock.new
    saved = false
    ActiveRecord::Base.transaction do
      if saved = @product.update_attributes(params[:product])
        if @stock.new_record? and params[:product][:stockable] == "1"
          @stock = Stock.new(params[:stock])
          @stock.product_id = @product.id
          save = false unless @stock.save
        elsif !@stock.new_record? and Warehouse.count > 0
          save = false unless @stock.add_or_update(params[:stock], @product.id)
        end
        @product.errors.add_from_record(@stock)
      end
      raise ActiveRecord::Rollback unless saved
    end
    return if save_and_redirect(@product, :saved=>saved)
    t3e @product.attributes
    render_restfully_form
  end

  def change_quantities
    @stock = Stock.find(:first, :conditions=>{:warehouse_id=>params[:warehouse_id], :product_id=>session[:product_id]})
    if @stock.nil?
      @stock = Stock.new(:quantity_min=>1, :quantity_max=>0, :critic_quantity_min=>0)
    end
  end

end
