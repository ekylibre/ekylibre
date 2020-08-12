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

    def show
      super

      if @activity_production.present?
        harvest_advisor = ::Interventions::Phytosanitary::PhytoHarvestAdvisor.new
        @reentry_possible = harvest_advisor.reentry_possible?(@activity_production.support, Time.zone.now)
      end
    end

    def new
      #params.keys == %i[cultivable_zone_id, activity_id, campaign_id]
      if params[:cultivable_zone_id].present?
        cultivable_zone_shape = CultivableZone.find_by(id: params[:cultivable_zone_id]).shape 
      end

      @activity_production = resource_model.new(
        activity_id: (params[:activity_id]), 
        campaign_id: (params[:campaign_id]), 
        cultivable_zone_id: (params[:cultivable_zone_id]), 
        custom_fields: (params[:custom_fields]), 
        irrigated: (params[:irrigated]), 
        nitrate_fixing: (params[:nitrate_fixing]), 
        rank_number: (params[:rank_number]), 
        season_id: (params[:season_id]), 
        size_indicator_name: (params[:size_indicator_name]), 
        size_unit_name: (params[:size_unit_name]), 
        size_value: (params[:size_value]), 
        started_on: (params[:started_on]), 
        state: (params[:state]), 
        stopped_on: (params[:stopped_on]), 
        support_id: (params[:support_id]), 
        support_nature: (params[:support_nature]), 
        support_shape: (params.fetch(:support_shape, cultivable_zone_shape)),
        tactic_id: (params[:tactic_id]), 
        usage: (params[:usage])
      )

      t3e(@activity_production.attributes.merge(name: (@activity_production.name)))
      render(locals: { cancel_url: :back, with_continue: false })
    end

    def create
      begin
        super

      rescue ActiveRecord::RecordInvalid
        notify_error_now(:empty_shape.tl)
        render :new
      end
    end
  end
end
