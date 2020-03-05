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

    manage_restfully except: %i[index show], subclass_inheritance: true

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

    def index
      respond_to do |format|
        format.html
        format.xml { render xml: resource_model.all }
        format.json { render json: resource_model.all }
        format.pdf {
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later('Printers::LandParcelRegisterCampaignPrinter', template: template, campaign: current_campaign, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to backend_activities_path
        }
      end
    end

    def show
      return unless @activity = find_and_check

      respond_to do |format|
        format.html do

          activity_crops = Plant
                             .joins(:inspections)
                             .where(activity_production_id: @activity.productions.map(&:id),
                                    dead_at: nil)
                             .where.not(inspections: { forecast_harvest_week: nil })
                             .uniq

          @crops = initialize_grid(activity_crops, decorate: true)

          t3e @activity
        end

        format.pdf do
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later('Printers::LandParcelRegisterActivityPrinter', template: template, campaign: current_campaign, activity: @activity, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to backend_activity_path(@activity)
        end
      end
      harvest_advisor = ::Interventions::Phytosanitary::PhytoHarvestAdvisor.new
      @reentry_possible = harvest_advisor.reentry_possible?(@activity, Time.zone.now)
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

  end
end
