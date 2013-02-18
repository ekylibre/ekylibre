# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
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

class Backend::PlacesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :description
    # t.column :name, :through => :establishment
    # t.column :name, :through => :parent, :url => true
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of warehouses
  def index

  end


  # Displays details of one warehouse selected with +params[:id]+
  def show
    return unless @place = find_and_check(:place)
    session[:current_place_id] = @place.id
    t3e @place.attributes
  end

end
