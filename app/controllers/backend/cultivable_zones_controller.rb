# coding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

class Backend::CultivableZonesController < Backend::LandParcelGroupsController
  manage_restfully(:t3e => {:name => :name})

  unroll

  # INDEX
  list do |t|
    t.column :name, url: true
    t.column :work_number
    t.column :clusters_work_number
    t.column :net_surface_area, datatype: :measure
    # t.column :unit
    t.action :edit
    t.action :destroy
  end

  # content production on current cultivable land parcel
  list(:productions, model: :production_supports, conditions: {storage_id: 'params[:id]'.c}, order: {started_at: :desc}) do |t|
    t.column :production, url: true
    t.column :exclusive, hidden: true
    t.column :started_at
    t.column :stopped_at, hidden: true
  end

end
