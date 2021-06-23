# == License
# Ekylibre - Simple agricultural ERP
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

module Backend
  class AnimalGroupsController < Backend::ProductGroupsController
    manage_restfully

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    list do |t|
      # t.action :show, url: {format: :pdf}, image: :print
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :variant, url: true
      t.column :member_variant, url: true
      t.column :description
    end

    list(:animals, model: :product_memberships, conditions: { group_id: 'params[:id]'.c }, order: :started_at) do |t|
      t.column :member, url: true
      t.column :started_at
      t.column :stopped_at
    end

    list(:places, model: :product_localizations, conditions: { product_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.column :container, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
    end

    # List interventions for one group
    list(:interventions, conditions: ["#{Intervention.table_name}.nature = ? AND interventions.id IN (SELECT animals_interventions.intervention_id FROM animals_interventions JOIN campaigns_interventions ON campaigns_interventions.intervention_id = animals_interventions.intervention_id WHERE animals_interventions.animal_group_id = ? AND campaigns_interventions.campaign_id = ?)", 'record', 'params[:id]'.c, 'current_campaign'.c], order: { created_at: :desc }, line_class: :status) do |t|
      t.column :name, url: true
      t.column :started_at
      t.column :human_working_duration, on_select: :sum, value_method: 'working_duration.in(:second).in(:hour)', datatype: :decimal
      t.column :human_input_quantity_names, label: :inputs, value_method: 'human_input_quantity_names'
      t.column :total_cost, label_method: 'costing&.decorate&.human_total_cost', currency: true, datatype: :decimal
      t.column :stopped_at, hidden: true
      t.column :issue, url: true
    end
  end
end
