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

class InventoriesController < AdminController

  list do |t|
    t.column :created_on
    t.column :changes_reflected
    t.column :label, :through=>:responsible, :url=>true
    t.column :comment
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :reflect, :if=>'RECORD.reflectable?', :image=>"action", 'data-confirm' => :are_you_sure
    t.action :edit,  :if=>'!RECORD.changes_reflected? '
    t.action :destroy, :if=>'!RECORD.changes_reflected? '
  end

  # Displays the main page with the list of inventories
  def index
    if Product.stockables.count.zero?
      notify_now(:need_stocks_to_create_inventories)
    end
  end

  list(:lines, :model=>:inventory_lines, :conditions=>{:inventory_id=>['params[:id]'] }, :order=>'warehouse_id') do |t|
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

  list(:lines_create, :model=>:stocks, :pagination=>:none, :order=>"#{Warehouse.table_name}.name, #{Product.table_name}.name") do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:product, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :quantity, :precision=>3
    t.column :label, :through=>:unit
    t.text_field :quantity
  end

  list(:lines_update, :model=>:inventory_lines, :conditions=>{:inventory_id=>['session[:current_inventory_id]'] }, :pagination=>:none, :order=>"#{Warehouse.table_name}.name, #{Product.table_name}.name") do |t|
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:product, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :theoric_quantity, :precision=>3
    t.text_field :quantity
  end


  def new
    if Product.stockables.count.zero?
      notify_warning(:need_stocks_to_create_inventories)
      redirect_to_back
    end
    notify_warning_now(:validates_old_inventories) if Inventory.find_all_by_changes_reflected(false).size >= 1
    @inventory = Inventory.new(:responsible_id=>@current_user.id)
  end

  def create
    if Product.stockables.count.zero?
      notify_warning(:need_stocks_to_create_inventories)
      redirect_to_back
    end
    notify_warning_now(:validates_old_inventories) if Inventory.find_all_by_changes_reflected(false).size >= 1
    @inventory = Inventory.new(params[:inventory])
    params[:lines_create] ||= {}
    params[:lines_create].each{|k,v| v[:stock_id]=k}
    # raise Exception.new(params[:lines_create].inspect)
    if @inventory.save
      @inventory.set_lines(params[:lines_create].values)
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
        # @inventory.set_lines(params[:lines_create].values)
        for id, attributes in (params[:lines_update]||{})
          il = InventoryLine.find_by_id(id).update_attributes!(attributes)
        end
      end
      redirect_to :action=>:index
      return
    end
    render :edit
  end

end
