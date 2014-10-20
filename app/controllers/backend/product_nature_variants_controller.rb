# encoding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
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

  manage_restfully_incorporation

  unroll

  list do |t|
    t.column :name, url: true
    t.column :nature, url: true
    t.column :unit_name
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  list(:prices, model: :catalog_prices, conditions: {variant_id: 'params[:id]'.c}, order: {started_at: :desc}) do |t|
    t.column :amount, url: true, currency: true
    t.column :all_taxes_included
    t.column :started_at
    t.column :stopped_at
    t.column :catalog, url: true
    t.action :destroy, if: :destroyable?
  end

  list(:products, conditions: {variant_id: 'params[:id]'.c}, order: {born_at: :desc}) do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :born_at
    t.column :net_mass
    t.column :net_volume
    t.column :population
  end

  def last_purchase_item
    return unless @product_nature_variant = find_and_check
    begin
      last_purchase_item = @product_nature_variant.last_purchase_item_for(params[:supplier_id])
      render json: last_purchase_item
    rescue
      notify_error :record_not_found
      redirect_to_back
    end
  end

end
