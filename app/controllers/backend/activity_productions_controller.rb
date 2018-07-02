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
  class ActivityProductionsController < Backend::BaseController
    manage_restfully(t3e: { name: :name }, creation_t3e: true, except: :index)

    unroll :rank_number, activity: :name, support: :name

    def index
      redirect_to backend_activities_path
    end

    before_action only: :new do
      redirect_to backend_activity_productions_path if params[:activity_id].nil? || params[:campaign_id].nil?
    end

    # List interventions for one production support
    list(:interventions, conditions: ["#{Intervention.table_name}.nature = ? AND interventions.id IN (SELECT intervention_id FROM activity_productions_interventions WHERE activity_production_id = ?)", 'record', 'params[:id]'.c], order: { created_at: :desc }, line_class: :status) do |t|
      t.column :name, url: true
      # t.status
      t.column :started_at
      t.column :human_working_duration
      t.column :human_target_names
      t.column :human_working_zone_area
      t.column :stopped_at, hidden: true
      t.column :issue, url: true
      # t.column :provisional
    end

    list(:plants, model: :plant, conditions: { activity_production_id: 'params[:id]'.c }, order: { name: :asc }, line_class: :status) do |t|
      t.column :name, url: true
      t.column :work_number, hidden: true
      t.column :variety
      t.column :work_name, through: :container, hidden: true, url: true
      t.column :net_surface_area, datatype: :measure
      t.status
      t.column :born_at
      t.column :dead_at
    end
  end
end
