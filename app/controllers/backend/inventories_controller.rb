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
  manage_restfully except: :index # only: [:show, :destroy]

  unroll

  list do |t|
    t.column :name, url: true
    t.column :achieved_at
    t.column :reflected_at
    t.column :reflected
    t.column :responsible, url: true
    # t.column :description
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :reflect, if: :reflectable?, image: "action", confirm: :are_you_sure
    t.action :edit,    if: :editable?
    t.action :destroy, if: :destroyable?
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
    t.column :expected_population, precision: 3
    t.column :population, precision: 3
    t.column :unit_name
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
