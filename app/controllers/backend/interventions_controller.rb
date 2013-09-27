# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2013 Brice Texier
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
class Backend::InterventionsController < BackendController
  manage_restfully :t3e => {:procedure_name => "Procedo[RECORD.procedure].human_name".c}

  unroll

  # INDEX

  list do |t|
    t.column :procedure, :url => true
    t.column :name, :through => :production, :url => true
    t.column :name, :through => :incident, :url => true
    t.column :state
    t.column :casting
    # t.action :play
    t.action :destroy, :if => :destroyable?
  end

  # SHOW

  list(:casts, :model => :intervention_casts, :conditions => {intervention_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :variable
    t.column :name, :through => :actor, :url => true
    # t.column :indicator
    # t.column :measure_quantity
    # t.column :measure_unit
  end

  list(:operations, :conditions => {intervention_id: 'params[:id]'.c}, :order => "started_at") do |t|
    t.column :position
    # t.column :name, :url => true
    # t.column :description
    # t.column :duration
    t.column :started_at
    t.column :stopped_at
    t.column :duration
  end

end
