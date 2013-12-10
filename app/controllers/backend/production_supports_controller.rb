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

class Backend::ProductionSupportsController < BackendController
  manage_restfully

  unroll includes: [{production: [:activity, :campaign, :variant]}, :storage]

  list do |t|
    t.column :production, url: true
    t.column :storage, url: true
    t.column :exclusive
    t.column :started_at
    t.column :stopped_at
  end

  # List procedures for one production
  list(:interventions, conditions: {production_support_id: 'params[:id]'.c}, order: {created_at: :desc}, line_class: :status) do |t|
    # t.column :name
    t.column :name, url: true
    #t.column :name, through: :storage, url: true
    t.column :state
    t.column :incident, url: true
    t.column :started_at
    t.column :stopped_at
    # t.column :provisional
  end

  # List markers
  list(:markers, model: :production_support_markers, conditions: {production_support_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.column :indicator_name, url: true
    t.column :aim
    t.column :value
    t.column :started_at
    t.column :stopped_at
  end

end
