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

class InventoriesController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :created_on
    t.column :changes_reflected
    t.column :label, :through=>:responsible, :url=>true
    t.column :comment
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :reflect, :if=>'RECORD.company.inventories.find_all_by_changes_reflected(false).size <= 1 and !RECORD.changes_reflected', :image=>"action", :confirm=>:are_you_sure
    t.action :edit,  :if=>'!RECORD.changes_reflected? '
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'!RECORD.changes_reflected? '
  end

  # Displays the main page with the list of inventories
  def index
    if @current_company.stockable_products.size <= 0
      notify_now(:need_stocks_to_create_inventories)
    end    
  end

  list(:lines, :model=>:inventory_lines, :conditions=>{:company_id=>['@current_company.id'], :inventory_id=>['params[:id]'] }, :order=>'warehouse_id') do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:product, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :theoric_quantity, :precision=>3
    t.column :quantity, :precision=>3
    t.column :name, :through=>:unit
  end

  # Displays details of one inventory selected with +params[:id]+
  def show
    return unless @inventory = find_and_check(:inventory)
    session[:current_inventory_id] = @inventory.id
    respond_to do |format|
      format.html
      format.pdf { render_print_inventory(@inventory) }
    end
  end

  list(:lines_create, :model=>:stocks, :conditions=>{:company_id=>['@current_company.id'] }, :pagination=>:none, :order=>'warehouse_id') do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:product, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :quantity, :precision=>3
    t.column :label, :through=>:unit
    t.text_field :quantity
  end

  list(:lines_update, :model=>:inventory_lines, :conditions=>{:company_id=>['@current_company.id'], :inventory_id=>['session[:current_inventory_id]'] }, :pagination=>:none, :order=>'warehouse_id') do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:product, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :theoric_quantity, :precision=>3
    t.text_field :quantity
  end


  def new
    if @current_company.stockable_products.size <= 0
      notify_warning(:need_stocks_to_create_inventories)
      redirect_to_back
    end
    notify_warning_now(:validates_old_inventories) if @current_company.inventories.find_all_by_changes_reflected(false).size >= 1
    @inventory = Inventory.new(:responsible_id=>@current_user.id)
  end

  def create
    if @current_company.stockable_products.size <= 0
      notify_warning(:need_stocks_to_create_inventories)
      redirect_to_back
    end
    notify_warning_now(:validates_old_inventories) if @current_company.inventories.find_all_by_changes_reflected(false).size >= 1
    @inventory = Inventory.new(params[:inventory])
    params[:inventory_lines_create] ||= {}
    params[:inventory_lines_create].each{|k,v| v[:stock_id]=k}
    # raise Exception.new(params[:inventory_lines_create].inspect)
    @inventory.company_id = @current_company.id
    if @inventory.save
      @inventory.set_lines(params[:inventory_lines_create].values)
      redirect_to :action=>:index
      return
    end
    render :new
  end

  def destroy
    return unless @inventory = find_and_check(:inventory)
    unless @inventory.changes_reflected?
      @inventory.destroy
    end
    redirect_to_current
  end

  def reflect
    return unless @inventory = find_and_check(:inventory)
    if @inventory.reflect_changes
      notify_success(:changes_have_been_reflected)
    else
      notify_error(:changes_have_not_been_reflected)
    end
    redirect_to :action=>:index 
  end

  def edit
    return unless @inventory = find_and_check(:inventory)
    session[:current_inventory_id] = @inventory.id
    t3e @inventory.attributes
  end

  def update
    return unless @inventory = find_and_check(:inventory)
    session[:current_inventory_id] = @inventory.id
    unless @inventory.changes_reflected
      if @inventory.update_attributes(params[:inventory])
        # @inventory.set_lines(params[:inventory_lines_create].values)
        for id, attributes in (params[:inventory_lines_update]||{})
          il = @current_company.inventory_lines.find_by_id(id).update_attributes!(attributes) 
        end
      end
      redirect_to :action=>:index
      return
    end
    render :edit
  end

end
