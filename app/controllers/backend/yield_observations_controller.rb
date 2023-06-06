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
  class YieldObservationsController < Backend::BaseController
    manage_restfully except: %i[update destroy]

    def self.list_conditions
      code = search_conditions("yield_observations" => %i[number description]) + " ||= []\n"
      code << "if params[:plant_id].present?\n"
      code << "   c[0] << ' AND #{YieldObservation.table_name}.id IN (SELECT yield_observation_id FROM #{ProductsYieldObservation.table_name} WHERE product_id = ?)'\n"
      code << "  c << params[:plant_id]\n"
      code << "end\n"

      code << "if params[:activity_id].present?\n"
      code << "   c[0] << ' AND #{YieldObservation.table_name}.activity_id IN (?)'\n"
      code << "  c << params[:activity_id]\n"
      code << "end\n"

      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{YieldObservation.table_name}.observed_at::DATE BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"

      code << "c\n "
      code.c
    end

    list(conditions: list_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :observed_at
      t.column :activity, url: { controller: '/backend/activities', id: 'RECORD.activity.id'.c }
      t.column :plants_name, label: :crops
      t.column :description
      t.column :vegetative_stage, hidden: true
      t.column :issues_name, label: :issues, hidden: true
    end

    list(:plants, model: :products_yield_observations, joins: :plant, conditions: ['yield_observation_id = ?', 'params[:id]'.c]) do |t|
      t.column :plant, url: true
      t.column :vegetative_stage
      t.column :working_zone_area, datatype: :measure
    end

    def show
      return unless @yield_observation = find_and_check

      t3e(@yield_observation.attributes)
    end

    def edit
      return unless @yield_observation = find_and_check

      t3e(@yield_observation.attributes)
      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    def update
      return unless @yield_observation = find_and_check

      t3e(@yield_observation.attributes)
      issues_attributes = params[:yield_observation][:issues_attributes]
      if issues_attributes
        issues_attributes.values.each do |issue_attributes|
          if issue_attributes[:_destroy] == '1'
            issues = @yield_observation.issues_of_same_issue_nature(issue_attributes[:id])
            issues.delete_all
          elsif issue_attributes[:id]
            issues = @yield_observation.issues_of_same_issue_nature(issue_attributes[:id])
            issues.update_all(issue_nature_id: issue_attributes[:issue_nature_id])
          else
            issue_nature = IssueNature.find(issue_attributes[:issue_nature_id])
            @yield_observation.plants.each do |plant|
              @yield_observation.issues.build(observed_at: @yield_observation.observed_at, issue_nature: issue_nature, target: plant)
            end
          end
        end
      end
      @yield_observation.attributes = permitted_params
      return if save_and_redirect(@yield_observation, url: { action: :show }, notify: :observation_updated, identifier: :number)

      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    def destroy
      return unless @yield_observation = find_and_check

      if @yield_observation.destroyable?
        @yield_observation.destroy
        notify_success(:record_has_been_correctly_removed)
      else
        notify_error(:record_cannot_be_removed)
      end
      redirect_to(params[:redirect] || { controller: :'backend/yield_observations', action: :index })
    end

    def permitted_params
      params.require(:yield_observation).permit!
    end
  end
end
