# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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
  class WineTanksController < Backend::BaseController
    list model: :products, scope: [:availables, "can('store(wine)')".c, "can('store_liquid')".c] do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :work_number, url: true
      t.column :name, url: true
      t.column :contents_name, datatype: :text
      t.column :nominal_storable_net_volume, datatype: :measure
      t.column :container, url: true
    end

    def index; end
  end
end
