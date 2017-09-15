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
  class DistrictsController < Backend::BaseController
    manage_restfully

    unroll

    list(children: :postal_zones, conditions: search_conditions(districts: %i[code name]), order: :name) do |t|
      t.action :new, url: { controller: :postal_zones, district_id: 'RECORD.id'.c, id: 'nil'.c }
      t.action :edit
      t.action :destroy
      t.column :name
      t.column :code
    end
  end
end
