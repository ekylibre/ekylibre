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

      code << <<~RUBY
        c[0] << " AND #{ProductNatureVariant.table_name}.active = 't'"
        c
      RUBY

      code
    end

    list(conditions: matters_conditions, join: :variant) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :work_number
      t.column :name, url: true
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :variety
      t.column :population
      t.column :unit_name
      t.column :container, url: true
      t.column :description
      t.column :derivative_of
    end
  end
end
