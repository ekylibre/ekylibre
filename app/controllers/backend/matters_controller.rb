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

class Backend::MattersController < Backend::ProductsController


  # params:
  #   :q Text search
  #   :working_set
  def self.local_conditions
    code = search_conditions(products: [:name, :number], product_nature_variants: [:name]) + " ||= []\n"
    code << "unless params[:working_set].blank?\n"
    code << "  item = Nomen::WorkingSets.find(params[:working_set])\n"
    code << "  puts item.expression.red\n"
    code << "  c[0] << \" AND products.nature_id IN (SELECT id FROM product_natures WHERE \#{WorkingSet.to_sql(item.expression)})\"\n"
    code << "end\n"
    code << "c\n"
    return code.c
  end


  list(conditions: local_conditions) do |t|
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :edit
    t.action :destroy, if: :destroyable?
    t.column :number, url: true
    t.column :name, url: true
    t.column :variant, url: true
    t.column :variety
    t.column :container, url: true
    t.column :description
  end

end
