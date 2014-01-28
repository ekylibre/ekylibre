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
  manage_restfully t3e: {procedure_name: "RECORD.reference.human_name".c}

  unroll

  def self.interventions_conditions
    code = ""
    code = search_conditions(:interventions => [:state], :activities => [:name], :campaigns => [:name], :productions => [:name], :products => [:name]) + " ||= []\n"
    code << "unless params[:state].blank?\n"
    code << "  c[0] << ' AND state IN ?'\n"
    code << "  c << params[:state].flatten\n"
    code << "end\n"
    code << "c[0] << ' AND ' + params[:nature].join(' AND ') unless params[:nature].blank?\n"
    code << "if params[:mode] == 'next'\n"
    code << "elsif params[:mode] == 'previous'\n"
    code << "elsif params[:mode] != 'all'\n" # currents
    code << "end\n"
    code << "c\n "
    return code.c
  end

  # INDEX
  # @TODO conditions: interventions_conditions, joins: [:production, :activity, :campaign, :storage]

  list(order: {started_at: :desc}, line_class: :status) do |t|
    t.column :reference_name, label_method: :name, url: true
    t.column :production, url: true, hidden: true
    t.column :campaign, url: true
    t.column :activity, url: true, hidden: true
    t.column :state, hidden: true
    t.column :started_at
    t.column :stopped_at, hidden: true
    t.status
    t.column :issue, url: true
    t.column :casting
    t.action :run, :if => :runnable?, method: :post, confirm: true
    t.action :edit, :if => :updateable?
    t.action :destroy, :if => :destroyable?
  end

  # SHOW

  list(:casts, model: :intervention_casts, conditions: {intervention_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.column :name, sort: :reference_name
    t.column :actor, url: true
    t.column :human_roles, sort: :roles, label: :roles
    t.column :population
    t.column :unit_name, through: :variant
    t.column :variant, url: true
    # t.column :indicator
    # t.column :measure_quantity
    # t.column :measure_unit
  end

  list(:operations, conditions: {intervention_id: 'params[:id]'.c}, order: :started_at) do |t|
    t.column :reference_name
    t.column :description
    # t.column :name, url: true
    # t.column :description
    # t.column :duration
    t.column :started_at
    t.column :stopped_at
    t.column :duration
  end

  def run
    return unless intervention = find_and_check
    intervention.run!
    redirect_to backend_intervention_url(intervention)
  end

end
