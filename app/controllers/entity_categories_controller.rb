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

class EntityCategoriesController < ApplicationController
  manage_restfully 

  list(:prices, :model=>:prices, :conditions=>{:company_id=>['@current_company.id'], :active=>true, :category_id=>['session[:category]']}) do |t|
    t.column :name, :through=>:product, :url=>true
    t.column :pretax_amount
    t.column :amount
    t.column :name, :through=>:tax
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :code
    t.column :name
    t.column :description
    t.column :by_default
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of entity categories
  def index
  end

  # Displays details of one entity category selected with +params[:id]+
  def show
    return unless @entity_category = find_and_check(:entity_category)
    session[:category] = @entity_category.id
    @category_prices_count = @current_company.prices.find(:all, :conditions=>{:active=>true, :category_id=>@entity_category.id}).size
    t3e @entity_category.attributes
  end

end
