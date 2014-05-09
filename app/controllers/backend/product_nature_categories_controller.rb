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

class Backend::ProductNatureCategoriesController < BackendController
  manage_restfully

  manage_restfully_incorporation

  unroll

  list do |t|
    t.column :name, url: true
    t.column :saleable
    t.column :purchasable
    t.column :storable
    t.column :depreciable
    t.action :new,  on: :none
    t.action :pick, on: :none
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  list(:products, conditions: {category_id: 'params[:id]'.c}, order: {born_at: :desc}) do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :born_at
    t.column :net_mass
    t.column :net_volume
    t.column :population
  end

  list(:product_natures, conditions: {category_id: 'params[:id]'.c}, order: :name) do |t|
    t.column :name, url: true
    t.column :variety
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

end
