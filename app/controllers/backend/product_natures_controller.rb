# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
  class ProductNaturesController < Backend::BaseController
    include Pickable

    manage_restfully except: %i[edit update], population_counting: :decimal, active: true

    importable_from_lexicon :variant_natures

    unroll

    def self.product_natures_conditions(_options = {})
      code = search_conditions(product_natures: %i[number name description]) + "\n"
      code << "if params[:s] == 'active'\n"
      code << "  c[0] += ' AND product_natures.active = ?'\n"
      code << "  c << true\n"
      code << "elsif params[:s] == 'inactive'\n"
      code << "  c[0] += ' AND product_natures.active = ?'\n"
      code << "  c << false\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: product_natures_conditions) do |t|
      t.action :edit, url: { controller: '/backend/product_natures' }
      t.action :destroy, url: { controller: '/backend/product_natures' }, if: :destroyable?
      t.column :name, url: { controller: '/backend/product_natures' }
      t.column :number, url: { controller: '/backend/product_natures' }
      t.column :active
      t.column :variety
      t.column :derivative_of
    end

    list(:variants, model: :product_nature_variants,
                    conditions: { nature_id: 'params[:id]'.c }, order: :name) do |t|
      t.action :new, on: :none, url: { nature_id: 'params[:id]'.c, redirect: 'request.fullpath'.c }
      t.action :edit, url: { controller: :product_nature_variants }
      t.action :destroy, url: { controller: :product_nature_variants }
      t.column :active
      t.column :number, url: { namespace: :backend }
      t.column :name, url: { namespace: :backend }
      t.column :variety
      t.column :derivative_of
      t.column :unit_name
    end

    def edit
      @product_nature = find_and_check
      @form_url = backend_product_nature_path(@product_nature)
      @key = 'product_nature'
      t3e(@product_nature.attributes)
    end

    def update
      return unless @product_nature = find_and_check(:product_nature)
      t3e(@product_nature.attributes)
      @product_nature.attributes = permitted_params
      return if save_and_redirect(@product_nature, url: params[:redirect] || ({ action: :show, id: 'id'.c }), notify: (params[:redirect] ? :record_x_updated : false), identifier: :name)
      @form_url = backend_product_nature_path(@product_nature)
      @key = 'product_nature'
      render(locals: { cancel_url: {:action=>:index}, with_continue: false })
    end

    def compatible_varieties
      product_nature = ProductNature.find_by(id: params[:id])
      return if product_nature.nil?
      varieties = Nomen::Variety.find(product_nature.variety).self_and_children
      render json: { data: varieties.map { |variety| {name: variety.name, human_name: variety.human_name }} }
    end
  end
end
