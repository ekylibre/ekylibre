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
  class LandParcelsController < Backend::MattersController
    # params:
    #   :q Text search
    def self.land_parcels_conditions
      code = ''
      code = search_conditions(products: %i[name number]) + " ||= []\n"
      code << "c\n"
      code.c
    end

    list(conditions: land_parcels_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :work_number
      t.column :identification_number
      t.column :net_surface_area, datatype: :measure
      t.column :born_at
      t.column :dead_at
    end
  end
end
