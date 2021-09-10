# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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
  class MattersController < Backend::ProductsController
    before_action :save_search_preference, only: :index

    def self.matters_conditions
      code = list_conditions
      code << "c[0] << \" AND #{ProductNatureVariant.table_name}.type like ?\"\n"
      code << "c << '%Variants::Article%'\n"
      code << "c[0] << \" AND #{ProductNatureVariant.table_name}.active = ?\"\n"
      code << "c << 't'\n"

      # Display matter with population > 0
      code << "if params[:s] == 'available'\n"
      code << "  c[0] << \" AND #{Product.table_name}.id IN (SELECT product_populations.product_id FROM product_populations INNER JOIN (SELECT product_id, MAX(started_at) as started_at FROM product_populations GROUP BY product_id) last_population ON product_populations.product_id = last_population.product_id and product_populations.started_at = last_population.started_at WHERE value > 0)\"\n"
      code << "end\n"

      # Display matter by sub-nature
      code << "if params[:sub_nature_id].present?\n"
      code << "  if params[:sub_nature_id] == 'Other'\n"
      code << "   c[0] << \" AND #{ProductNatureVariant.table_name}.type =? \"\n"
      code << "     c << 'Variants::ArticleVariant'\n"
      code << "  else \n"
      code << "   c[0] << \" AND #{ProductNatureVariant.table_name}.type =? \"\n"
      code << "     c << 'Variants::Articles::'+ params[:sub_nature_id].to_s + 'Article'\n"
      code << "  end\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: matters_conditions, join: :variant, distinct: true) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :work_number
      t.column :name, url: true
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :variety
      t.column :population
      t.column :conditioning_unit
      t.column :container, url: true
      t.column :description
      t.column :derivative_of
    end
  end
end
