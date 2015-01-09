# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
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
class Backend::TrackingsController < BackendController
  manage_restfully

  unroll :serial, :name, producer: :full_name

  list(order: :name) do |t|
    t.column :active
    t.column :serial, url: true
    t.column :name
    t.column :product
    t.column :producer
    t.action :edit
    t.action :destroy
  end

  list(:products, model: :products, conditions: {tracking_id: 'params[:id]'.c}, order: {born_at: :asc}) do |t|
    t.column :number, url: true
    t.column :name
    t.column :born_at
    t.column :container
  end

end
