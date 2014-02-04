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

class Backend::InventoriesController < BackendController
  manage_restfully only: [:show, :destroy]

  unroll

  list do |t|
    t.column :created_at
    t.column :reflected
    t.column :responsible, url: true
    # t.column :description
    # t.action :show, url: {:format => :pdf}, image: :print
    t.action :reflect, :if => :reflectable?, image: "action", :confirm => :are_you_sure
    t.action :edit,    :if => :editable?
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of inventories
  def index
    unless ProductNature.stockables.any?
      notify_now(:need_stocks_to_create_inventories)
    end
  end

  list(:items, model: :inventory_items, conditions: {inventory_id: 'params[:id]'.c}, order: :id) do |t|
    # t.column :name, through: :building, url: true
    t.column :product, url: true
    # t.column :serial_number, through: :product
    t.column :theoric_population, :precision => 3
    t.column :population, :precision => 3
    t.column :unit_name
  end

  # # Displays details of one inventory selected with +params[:id]+
  # def show
  #   return unless @inventory = find_and_check
  #   session[:current_inventory_id] = @inventory.id
  #   respond_to do |format|
  #     format.html
  #     format.pdf { render_print_inventory(@inventory) }
  #   end
  # end

  list(:items_create, model: :products, :pagination => :none, order: "#{ProductNature.table_name}.name") do |t|
    # t.column :name, through: :building, url: true
    t.column :name, url: true
    # t.column :serial_number, through: :tracking
    # t.column :population, :precision => 3
    t.column :unit_name
    t.text_field :population
  end

  list(:items_update, model: :inventory_items, conditions: {inventory_id: 'params[:id]'.c}, :pagination => :none, order: "#{Product.table_name}.name") do |t|
    t.column :container, url: true
    t.column :product, url: true
    # t.column :serial_number, through: :product
    t.column :theoric_population, :precision => 3
    t.text_field :population
    t.column :unit_name
  end

  def new
    if ProductNature.stockables.empty?
      notify_warning(:need_stocks_to_create_inventories)
      redirect_to_back
    end
    notify_warning_now(:validates_old_inventories) if Inventory.unreflecteds.any?
    @inventory = Inventory.new(responsible: current_user.person)
    # render_restfully_form
  end

  def create
    if ProductNature.stockables.empty?
      notify_warning(:need_stocks_to_create_inventories)
      redirect_to_back
    end
    notify_warning_now(:validates_old_inventories) if Inventory.unreflecteds.any?
    @inventory = Inventory.new(permitted_params)
    params[:items_create] ||= {}
    params[:items_create].each{|k,v| v[:stock_id]=k}
    # raise Exception.new(params[:items_create].inspect)
    if @inventory.save
      # TODO manage nested attributes
      # @inventory.set_items(params[:items_create].values)
      redirect_to action: :index
      return
    end
    # render_restfully_form
  end

  def edit
    return unless @inventory = find_and_check
    session[:current_inventory_id] = @inventory.id
    t3e @inventory.attributes
    # render_restfully_form
  end

  def update
    return unless @inventory = find_and_check
    session[:current_inventory_id] = @inventory.id
    unless @inventory.reflected
      if @inventory.update_attributes(permitted_params)
        # @inventory.set_items(params[:items_create].values)
        for id, attributes in (params[:items_update]||{})
          il = InventoryItem.find_by_id(id).update_attributes!(attributes)
        end
      end
      redirect_to action: :index
      return
    end
    # render_restfully_form
  end

  def reflect
    return unless @inventory = find_and_check
    if @inventory.reflect
      notify_success(:changes_have_been_reflected)
    else
      notify_error(:changes_have_not_been_reflected)
    end
    redirect_to action: :index
  end

end
