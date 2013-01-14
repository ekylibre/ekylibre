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

class ProductNatureCategoriesController < AdminController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :comment
    t.column :catalog_name
    t.column :catalog_description
    t.column :name, :through => :parent
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of product categories
  def index
  end

  list(:product_natures, :conditions => {:category_id => ['session[:current_product_nature_category_id]']}, :order => 'active DESC, name') do |t|
    t.column :number
    t.column :name, :url => true
    t.column :code, :url => true
    t.column :description
    t.column :active
    t.action :edit
    t.action :destroy
  end

  # Displays details of one product category selected with +params[:id]+
  def show
    return unless @product_nature_category = find_and_check
    session[:current_product_nature_category_id] = @product_nature_category.id
    t3e @product_nature_category.attributes
  end

end
