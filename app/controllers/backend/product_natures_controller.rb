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
    manage_restfully population_counting: :decimal, active: true

    manage_restfully_incorporation

    unroll

    def self.product_natures_conditions(_options = {})
      code = search_conditions(product_natures: %i[number name description],
                               product_nature_categories: [:name]) + "\n"
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
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :number, url: true
      t.column :category, url: true
      t.column :active
      t.column :variety
      t.column :derivative_of
    end

    list(:variants, model: :product_nature_variants,
                    conditions: { nature_id: 'params[:id]'.c }, order: :name) do |t|
      t.action :new, on: :none, url: { nature_id: 'params[:id]'.c, redirect: 'request.fullpath'.c }
      t.action :edit
      t.action :destroy
      t.column :active
      t.column :number, url: true
      t.column :name, url: true
      t.column :variety
      t.column :derivative_of
      t.column :unit_name
    end
  end
end
