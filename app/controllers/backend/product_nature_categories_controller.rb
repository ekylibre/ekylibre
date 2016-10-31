# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class ProductNatureCategoriesController < Backend::BaseController
    manage_restfully active: true, pictogram: :undefined

    manage_restfully_incorporation

    unroll

    list do |t|
      t.action :new, on: :none
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :saleable, hidden: true
      t.column :product_account, if: :saleable?, url: true
      t.column :purchasable, hidden: true
      t.column :charge_account, if: :purchasable?, url: true
      t.column :storable, hidden: true
      t.column :stock_account, if: :storable?, url: true
      t.column :depreciable, hidden: true
      t.column :fixed_asset_account, if: :depreciable?, url: true
    end

    list(:products, conditions: { category_id: 'params[:id]'.c }, order: { born_at: :desc }) do |t|
      t.column :name, url: true
      t.column :identification_number
      t.column :born_at
      t.column :net_mass
      t.column :net_volume
      t.column :population
    end

    list(:product_natures, conditions: { category_id: 'params[:id]'.c }, order: :name) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :variety
    end

    list(:taxations, model: :product_nature_category_taxations, conditions: { product_nature_category_id: 'params[:id]'.c }, order: :id) do |t|
      t.column :tax, url: true
      t.column :usage
    end
  end
end
