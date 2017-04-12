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
  class PostalZonesController < Backend::BaseController
    manage_restfully country: 'Preference[:country]'.c

    unroll

    autocomplete_for :name

    list(conditions: search_conditions(postal_zones: %i[postal_code name]), order: :name) do |t|
      t.action :edit
      t.action :destroy
      t.column :name
      t.column :postal_code
      t.column :city
      t.column :code
      t.column :district, url: true
      t.column :country
    end
  end
end
