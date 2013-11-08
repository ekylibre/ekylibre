# coding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

class Backend::MineralMattersController < BackendController

  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :population
    t.column :net_weight
    t.column :localize_in
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end

    # Liste des indicateurs de l'animal considéré
  list(:indicators, :model => :product_indicator_data, :conditions => {product_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
  end

end
