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

class EntityCategoriesController < AdminController
  manage_restfully

  list do |t|
    t.column :code, :url=>true
    t.column :name, :url=>true
    t.column :description
    t.column :by_default
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of entity categories
  def index
  end

  list(:prices, :model=>:prices, :conditions=>{:active=>true, :category_id=>['session[:current_entity_category_id]']}) do |t|
    t.column :name, :through=>:product, :url=>true
    t.column :pretax_amount
    t.column :amount
    t.column :name, :through=>:tax
    t.action :destroy
  end

  # Displays details of one entity category selected with +params[:id]+
  def show
    return unless @entity_category = find_and_check(:entity_category)
    session[:current_entity_category_id] = @entity_category.id
    t3e @entity_category.attributes
  end

end
