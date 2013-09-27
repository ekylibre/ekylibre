# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2013 Brice Texier, David Joulin
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

class Backend::ProductNatureVariantsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :name, through: :nature, url: true
    t.column :unit_name
    t.column :frozen_indicators
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  list(:prices, :model => :catalog_prices, :conditions => {variant_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :amount, url: true, currency: true
    t.column :all_taxes_included
    t.column :started_at
    t.column :stopped_at
    t.column :name, through: :catalog, url: true
  end

  list(:products, :conditions => {variant_id: 'params[:id]'.c}, :order => "born_at DESC") do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :born_at
    t.column :net_weight
    t.column :net_volume
    t.column :population
  end

end
