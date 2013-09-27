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

  unroll

  list do |t|
    t.column :name, url: true
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

# content product list of the consider product
  list(:content_product, :model => :product_localizations, :conditions => ["container_id = ? ",['session[:current_product_group_id]']], :order => "started_at DESC") do |t|
    t.column :name, through: :product, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # localization of the consider product
  list(:place, :model => :product_localizations, :conditions => [" product_id = ? ",['session[:current_product_group_id]']], :order => "started_at DESC") do |t|
    t.column :name, through: :container, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # groups of the consider product
  list(:group, :model => :product_memberships, :conditions => [" member_id = ? ",['session[:current_product_group_id]']], :order => "started_at DESC") do |t|
    t.column :name, through: :group, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # members of the consider product
  list(:member, :model => :product_memberships, :conditions => [" group_id = ? ",['session[:current_product_group_id]']], :order => "started_at ASC") do |t|
    t.column :name, through: :member, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # indicators of the consider product
  list(:indicator, :model => :product_indicator_data, :conditions => [" product_id = ? ",['session[:current_product_group_id]']], :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
  end

  # incidents of the consider product
  list(:incident, :model => :incidents, :conditions => [" target_id = ? and target_type = 'Animal'",['session[:current_product_group_id]']], :order => "observed_at DESC") do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end

  # list(:events,:model  =>  :product_group_events, :conditions => {:animal_group_id => ['session[:current_animal_group_id]']}, :order => "started_at ASC") do |t|
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
