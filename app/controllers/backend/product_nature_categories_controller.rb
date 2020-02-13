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
    include Pickable

    manage_restfully except: %i[edit update], active: true, pictogram: :undefined

    importable_from_lexicon :variant_categories

    unroll

    def self.categories_conditions
      code = search_conditions(product_nature_categories: %i[name number]) + " ||= []\n"
      code << "c\n"
      code.c
    end

    list(conditions: categories_conditions) do |t|
      t.action :edit, url: { controller: '/backend/product_nature_categories' }
      t.action :destroy, url: { controller: '/backend/product_nature_categories' }, if: :destroyable?
      t.column :name, url: { controller: '/backend/product_nature_categories' }
      t.column :saleable, hidden: true
      t.column :product_account, if: :saleable?, url: { controller: '/backend/accounts' }
      t.column :purchasable, hidden: true
      t.column :charge_account, if: :purchasable?, url: { controller: '/backend/accounts' }
      t.column :storable, hidden: true
      t.column :stock_account, if: :storable?, url: { controller: '/backend/accounts' }
      t.column :depreciable, hidden: true
      t.column :fixed_asset_account, if: :depreciable?, url: { controller: '/backend/accounts' }
      t.column :variants_count, hidden: true
    end

    list(:products, conditions: { category_id: 'params[:id]'.c }, order: { born_at: :desc }) do |t|
      t.column :name, url: { controller: '/backend/products' }
      t.column :identification_number
      t.column :born_at
      t.column :net_mass
      t.column :net_volume
      t.column :population
    end

    list(:taxations, model: :product_nature_category_taxations, conditions: { product_nature_category_id: 'params[:id]'.c }, order: :id) do |t|
      t.column :tax, url: true
      t.column :usage
    end

    def edit
      @product_nature_category = find_and_check
      @form_url = backend_product_nature_category_path(@product_nature_category)
      @key = 'product_nature_category'
      t3e(@product_nature_category.attributes)
    end

    def update
      return unless @product_nature_category = find_and_check(:product_nature_category)
      t3e(@product_nature_category.attributes)
      @product_nature_category.attributes = permitted_params
      return if save_and_redirect(@product_nature_category, url: params[:redirect] || ({ action: :show, id: 'id'.c }), notify: (params[:redirect] ? :record_x_updated : false), identifier: :name)
      @form_url = backend_product_nature_category_path(@product_nature_category)
      @key = 'product_nature_category'
      render(locals: { cancel_url: {:action=>:index}, with_continue: false })
    end
  end
end
