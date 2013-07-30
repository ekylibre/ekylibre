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

class Backend::ProductPriceListingsController < BackendController
  unroll_all

  manage_restfully

  list do |t|
    t.column :code, :url => true
    t.column :name, :url => true
    t.column :description
    t.column :by_default
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of entity categories
  def index
  end

  list(:prices, :model => :product_prices, :conditions => {:active => true, :listing_id => ['session[:current_product_price_listing_id]']}) do |t|
    t.column :name, :through => :variant, :url => true
    t.column :pretax_amount
    t.column :amount
    t.column :name, :through => :tax
    t.action :destroy
  end

  # Displays details of one entity category selected with +params[:id]+
  def show
    return unless @product_price_listing = find_and_check(:product_price_listing)
    session[:current_product_price_listing_id] = @product_price_listing.id
    t3e @product_price_listing.attributes
  end

end
