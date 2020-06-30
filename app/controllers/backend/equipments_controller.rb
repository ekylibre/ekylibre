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
  class EquipmentsController < Backend::MattersController
    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    #   :activity_id
    def self.equipments_conditions
      code = ''
      code = search_conditions(products: %i[name work_number number description uuid],
                               product_nature_variants: [:name]) + " ||= []\n"
      code << "  if params[:variant_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{ProductNatureVariant.table_name}.id = ?\"\n"
      code << "    c << params[:variant_id].to_i\n"
      code << "  end\n"

      # filter by activity_id
      code << "  if params[:activity_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{Equipment.table_name}.id IN (SELECT target_id FROM target_distributions WHERE activity_id = ?)\"\n"
      code << "    c << params[:activity_id].to_i\n"
      code << "  end\n"

      code << "c\n"
      code.c
    end

    list(conditions: equipments_conditions, joins: :variants) do |t|
      t.action :edit
      t.action :destroy
      t.column :work_number, url: true
      t.column :name, url: true
      t.column :born_at
      t.status
      t.column :state, hidden: true
      t.column :container, url: true
    end
  end
end
