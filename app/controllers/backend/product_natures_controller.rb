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

class Backend::ProductNaturesController < BackendController
  unroll_all

  manage_restfully

  # management -> product_conditions
  def self.product_natures_conditions(options={})
    code = ""
    code = light_search_conditions(:product_natures => [:number, :name, :commercial_name, :description, :commercial_description])+"\n"
    code += "if session[:product_nature_state] == 'active'\n"
    code += "  c[0] += ' AND active = ?'\n"
    code += "  c << true\n"
    code += "elsif session[:product_nature_state] == 'inactive'\n"
    code += "  c[0] += ' AND active = ?'\n"
    code += "  c << false\n"
    code += "end\n"
    code += "if session[:product_nature_category_id].to_i > 0\n"
    code += "  c[0] += ' AND category_id = ?'\n"
    code += "  c << session[:product_nature_category_id].to_i\n"
    code += "end\n"
    code += "c\n"
    code
  end

  list(:conditions => product_natures_conditions) do |t|
    # t.column :number
    t.column :name, :through => :category, :url => true
    t.column :name, :url => true
    t.column :number, :url => true
    t.column :purchasable
    t.column :saleable
    t.column :storable
    t.column :variety
    t.column :label, :through => :unit
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of products
  def index
    session[:product_nature_state] = params[:s]||"all"
    session[:product_nature_category_id] = params[:category_id].to_i
  end


  list(:prices, :model => :product_price_template, :conditions => {:product_nature_id => ['session[:product_nature_id]'], :active => true}) do |t|
    t.column :name, :through => :supplier, :url => true
    t.column :name, :through => :listing, :url => true
    t.column :pretax_amount, :currency  =>  true
    t.column :amount, :currency  =>  true
    t.column :by_default
    # t.column :range
    t.action :edit
    t.action :destroy
  end

  #list(:product_moves, :conditions => {:product_id  => ['session[:product_id]']}, :line_class => 'RECORD.state', :order => "updated_at DESC") do |t|
    #t.column :name
    # t.column :name, :through => :origin
    # t.column :name, :through => :building, :url => true
    # t.column :name, :through => :tracking, :url => true
    #t.column :quantity
    #t.column :label, :through => :unit
    #t.column :mode
    # t.column :planned_on
    # t.column :moved_on
    #t.column :moved_at
  #end

  # list(:product_stocks, :conditions => ['#{ProductStock.table_name}.product_id = ?', ['session[:product_id]']], :line_class => 'RECORD.state', :order => "updated_at DESC") do |t|
  #   # t.column :name, :through => :building, :url => true
  #   t.column :name, :through => :product, :url => true
  #   t.column :minimal_quantity
  #   t.column :maximal_quantity
  #   # t.column :critic_quantity_min
  #   # t.column :virtual_quantity
  #   # t.column :quantity
  # end

  # Displays details of one product selected with +params[:id]+
  def show
    return unless @product_nature = find_and_check(:product_natures)
    session[:product_nature_id] = @product_nature.id
    t3e @product_nature.attributes
  end

  #def new
  #  @product_nature = ProductNature.new(:nature => ProductNature.nature.default_value)
   # # render_restfully_form
  #end

  #def create
  #  @product_nature = ProductNature.new(params[:product])
  #  @product_nature.duration = params[:product][:duration]
  #  @stock = ProductStock.new(params[:stock])
  #  ActiveRecord::Base.transaction do
  #    saved = @product_nature.save
  #    if @product_nature.stockable and saved
  #      @product_nature.product_id = @product_nature.id
  #      saved = false unless @stock.save
  #      @product_nature.errors.add_from_record(@stock)
  #    end
  #    raise ActiveRecord::Rollback unless saved
  #    return if save_and_redirect(@product_nature, :saved => saved)
  #  end
  #  # render_restfully_form
  #end

  #def destroy
  #  return unless @product_nature = find_and_check(:product_natures)
  #  if request.post? or request.delete?
  #    @product_nature.destroy
  #  end
  #  redirect_to_current
  #end

  #def edit
  #  return unless @product_nature = find_and_check(:product_natures)
  #  session[:product_nature_id] = @product_nature.id
    #@stock = @product_nature.default_stock || ProductStock.new
  #  t3e @product_nature.attributes
  #  # render_restfully_form
  #end

#  def update
  #  return unless @product_nature = find_and_check(:product_natures)
  #  session[:product_nature_id] = @product_nature.id
    #@stock = @product_nature.default_stock || ProductStock.new
 #   saved = false
  #  ActiveRecord::Base.transaction do
  #    if saved = @product_nature.update_attributes(params[:product_nature])
   #     if @stock.new_record? and params[:product_nature][:stockable] == "1"
   #       @stock = ProductStock.new(params[:stock])
  #        @stock.product_id = @product_nature.id
   #       save = false unless @stock.save
  #      elsif !@stock.new_record? and Building.count > 0
  #        save = false unless @stock.add_or_update(params[:stock], @product_nature.id)
  #      end
  #      @product_nature.errors.add_from_record(@stock)
  #    end
  #    raise ActiveRecord::Rollback unless saved
   # end
   # return if save_and_redirect(@product_nature, :saved => saved)
   # t3e @product_nature.attributes
   # # render_restfully_form
  #end

  #def change_quantities
   # @stock = ProductStock.find(:first, :conditions => {:building_id => params[:building_id], :product_nature_id => session[:product_nature_id]})
    #if @stock.nil?
     # @stock = ProductStock.new(:quantity_min => 1, :quantity_max => 0, :critic_quantity_min => 0)
    #end
  #end

end
