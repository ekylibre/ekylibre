# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::PostalZonesController < BackendController
  manage_restfully :country => "Preference[:country]".c, except: :show

  unroll

  autocomplete_for :name

  list(conditions: search_conditions(:postal_zones => [:postcode, :name]), order: :name) do |t|
    t.column :name
    t.column :postal_code
    t.column :city
    t.column :code
    t.column :district # , url: true
    t.column :country
    t.action :edit
    t.action :destroy
  end

end
