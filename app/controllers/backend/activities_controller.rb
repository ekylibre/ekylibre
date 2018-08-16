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
  class ActivitiesController < Backend::BaseController
    include InspectionViewable

    manage_restfully except: [:show], subclass_inheritance: true

    unroll

    list line_class: '(:success if RECORD.of_campaign?(current_campaign))'.c do |t|
      # t.action :show, url: {format: :pdf}, image: :print
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :nature
      t.column :family
      t.column :with_cultivation
      t.column :cultivation_variety, hidden: true
      t.column :with_supports
      t.column :support_variety, hidden: true
    end

    def show
      return unless @activity = find_and_check

      activity_crops = Plant
                       .joins(:inspections)
                       .where(activity_production_id: @activity.productions.map(&:id),
                              dead_at: nil)
                       .where.not(inspections: { forecast_harvest_week: nil })
                       .uniq

      @crops = initialize_grid(activity_crops, decorate: true)

      t3e @activity
    end

    # Duplicate activity basing on campaign
    def duplicate
      source = if params[:source_campaign_id]
                 Campaign.find(params[:source_campaign_id])
               else
                 current_campaign.preceding
               end
      activity = Activity.find_by(id: params[:source_activity_id])

      new_campaign = Campaign.find_by(id: params[:campaign_id]) || current_campaign

      campaign_diff = new_campaign.harvest_year - source.harvest_year

      # Productions
      productions = ActivityProduction.of_campaign(source)
      productions = productions.of_activity(activity) if activity
      productions.each do |production|
        updates = { campaign: new_campaign }
        if production.started_on
          updates[:started_on] = production.started_on + campaign_diff.year
        end
        if production.stopped_on
          updates[:stopped_on] = production.stopped_on + campaign_diff.year
        end
        production.duplicate!(updates)
      end

      # Budgets
      budgets = ActivityBudget.of_campaign(source)
      budgets = budgets.of_activity(activity) if activity
      budgets.each do |budget|
        budget.duplicate!(budget.activity, new_campaign)
      end
      redirect_to params[:redirect] || { action: :index }
    end

    # Returns wanted varieties proposition for given family_name
    def family
      unless family = Nomen::ActivityFamily[params[:name]]
        head :not_found
        return
      end
      data = {
        label: family.human_name,
        name: family.name
      }
      if family.cultivation_variety.present?
        data[:cultivation_varieties] = Nomen::Variety.selection_hash(family.cultivation_variety)
      end
      if family.support_variety.present?
        data[:support_varieties] = Nomen::Variety.selection_hash(family.support_variety)
      end
      render json: data
    end

    # List of productions for one activity
    list(:productions, model: :activity_production, conditions: { activity_id: 'params[:id]'.c, campaign_id: 'current_campaign'.c }, order: { started_on: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      # t.column :campaign, url: true
      # t.column :product_nature, url: true
      t.column :human_support_shape_area
      t.column :state
      t.column :started_on
      t.column :stopped_on
    end

    # List of distribution for one activity
    list(:distributions, model: :activity_distributions, conditions: { activity_id: 'params[:id]'.c }) do |t|
      t.column :affectation_percentage, percentage: true
      t.column :main_activity, url: true
    end

    # List of inspections
    list(:supports, model: :plant, conditions: { activity_production_id: 'ActivityProduction.joins(:activity).where(activity_id: params[:id]).pluck(:id)'.c }) do |t|
      t.column :name, url: true
      t.column :last_inspection_number, url: { controller: '/backend/inspections', id: 'RECORD.last_inspection_id'.c }
      t.column :last_inspection_forecast_harvest_week
      t.column :last_inspection_comment
      t.column :last_inspection_disease_percentage
    end
  end
end
