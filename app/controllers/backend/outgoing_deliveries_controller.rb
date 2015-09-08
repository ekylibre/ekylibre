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

class Backend::OutgoingDeliveriesController < Backend::BaseController
  manage_restfully except: [:new, :create]

  unroll

  list(conditions: search_conditions(outgoing_deliveries: [:number, :annotation], entities: [:number, :full_name])) do |t|
    t.action :edit
    t.action :destroy
    t.column :number, url: true
    t.column :annotation
    t.column :departed_at
    t.column :transporter, label_method: :full_name, url: true
    t.column :net_mass
  end

  list(:parcels, model: :outgoing_parcels, conditions: { delivery_id: 'params[:id]'.c }) do |t|
    t.column :number, url: true
    t.column :reference_number
    t.column :address, label_method: :coordinate
    t.column :sale, url: true
    t.column :sent_at
    t.column :net_mass
  end
end
