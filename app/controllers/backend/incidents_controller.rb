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

# -*- coding: utf-8 -*-
class Backend::IncidentsController < BackendController

  manage_restfully
  manage_restfully_picture

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    # t.column :name, through: :target, url: true
    t.column :gravity
    t.column :priority
    t.column :state
    t.action :edit
    t.action :new, url: {controller: :interventions, incident_id: 'RECORD.id'.c, id: nil}
    t.action :destroy, :if => :destroyable?
  end


  list(:interventions, conditions: {incident_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.column :nomen, url: true
    t.column :created_at
    t.column :natures
    t.column :state
  end

end
