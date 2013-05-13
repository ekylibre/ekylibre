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

class Backend::BuildingsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :description
    # t.column :name, :through => :establishment
    # t.column :name, :through => :parent, :url => true
    t.column :reservoir
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of buildings
  def index
    notify_now(:need_building_to_record_stock_moves) if Building.count.zero?
  end

  # list(:product_moves, :conditions => {:building_id => ['session[:current_building_id]']}) do |t|
  #   t.column :name
  #   t.column :planned_on
  #   t.column :moved_on
  #   t.column :quantity
  #   t.column :label, :through => :unit
  #   t.column :name, :through => :product, :url => true
  #   t.column :virtual
  #   # t.action :edit, :if => 'RECORD.generated != true'
  #   # t.action :destroy,:if => 'RECORD.generated != true'
  # end

  # list(:product_stocks, :conditions => {:building_id => ['session[:current_building_id]']}, :order => "quantity DESC") do |t|
  #   t.column :name, :through => :product,:url => true
  #   # t.column :name, :through => :tracking, :url => true
  #   t.column :weight, :through => :product, :label => :column
  #   t.column :quantity_max
  #   t.column :quantity_min
  #   t.column :critic_quantity_min
  #   t.column :virtual_quantity
  #   t.column :quantity
  # end

  # Displays details of one building selected with +params[:id]+
  def show
    return unless @building = find_and_check(:building)
    session[:current_building_id] = @building.id
    t3e @building.attributes
  end

end
