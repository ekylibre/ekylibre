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

class Backend::ProductGroupsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

  list(:products, :conditions => {:group_id => ['session[:current_product_group_id]']}, :order => "name ASC") do |t|
    t.column :name, :url => true
    t.column :work_number, :url => {:action => :show}
    t.column :born_at
  end

  # list(:meetings,:model  =>  :product_group_events, :conditions => {:animal_group_id => ['session[:current_animal_group_id]']}, :order => "started_at ASC") do |t|
  #   t.column :started_at
  #   t.column :description
  # end

  # Show a list of animals
  def index
  end

  # Show one Product with params_id
  def show
    return unless @product_group = find_and_check
    session[:current_product_group_id] = @product_group.id
    t3e @product_group
  end

end
