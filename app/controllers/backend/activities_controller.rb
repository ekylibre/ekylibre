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

    PLANT_FAMILY_ACTIVITIES = %w[plant_farming vine_farming].freeze

    unroll

    after_action :open_activity, only: :create, unless: -> { @activity.new_record? }

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
      t.column :isacompta_analytic_code, hidden: AnalyticSegment.where(name: 'activities').none?
    end

    def show
      return unless @activity = find_and_check

      @phytosanitary_document = DocumentTemplate.find_by(nature: :phytosanitary_register)
      @land_parcel_document = DocumentTemplate.find_by(nature: :land_parcel_register)
      @intervention_document = DocumentTemplate.find_by(nature: :intervention_register)
      @activity_cost_document = DocumentTemplate.find_by(nature: :activity_cost)
      @planned_budget_document = DocumentTemplate.find_by(nature: :planned_budget_sheet)
      @pfi_interventions = PfiCampaignsActivitiesIntervention.of_activity(@activity).of_campaign(current_campaign)
      respond_to do |format|
        format.html do

          activity_crops = Plant
                             .joins(:inspections)
                             .where(activity_production_id: @activity.productions.map(&:id),
                                    dead_at: nil)
                             .where.not(inspections: { forecast_harvest_week: nil })
                             .distinct

          @crops = initialize_grid(activity_crops, decorate: true)

          t3e @activity
        end

        format.pdf do
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later(tl("activity_printers.show.#{template.nature}", locale: :eng), template: template, campaign: current_campaign, activity: @activity, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to backend_activity_path(@activity)
        end
      end
      @technical_itinerary_id = @activity&.default_tactics&.of_campaign(current_campaign)&.first&.technical_itinerary&.id
    end

    manage_restfully except: %i[index show]

    def index
      missing_code_count = Activity.where('isacompta_analytic_code IS NULL').count
      segment = AnalyticSegment.find_by(name: 'activities')
      if segment.presence && missing_code_count > 0
        notify_warning :fill_analytic_codes_of_your_activities.tl(segment: segment.name.text.downcase, missing_code_count: missing_code_count)
      end
      @currency = Onoma::Currency.find(Preference[:currency])
      @activities_of_campaign = Activity.of_campaign(current_campaign)
      @availables_activities = Activity.availables.where.not(id: @activities_of_campaign)
      @families = @activities_of_campaign.order(:family).collect(&:family).uniq
      @activities = @activities_of_campaign
                      .left_join_working_duration_of_campaign(current_campaign)
                      .left_join_issues_count_of_campaign(current_campaign)
                      .left_join_production_costs_of_campaign(current_campaign)

      @phytosanitary_document = DocumentTemplate.find_by(nature: :phytosanitary_register)
      @land_parcel_document = DocumentTemplate.find_by(nature: :land_parcel_register)
      @intervention_document = DocumentTemplate.find_by(nature: :intervention_register)
      @activity_cost_document = DocumentTemplate.find_by(nature: :activity_cost)
      @planned_budget_document = DocumentTemplate.find_by(nature: :planned_budget_sheet)
      @pfi_interventions = PfiCampaignsActivitiesIntervention.of_campaign(current_campaign)

      respond_to do |format|
        format.html
        format.xml { render xml: resource_model.all }
        format.json { render json: resource_model.all }
        format.pdf {
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later(tl("activity_printers.#{template.nature}", locale: :eng), template: template, campaign: current_campaign, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to backend_activities_path
        }
      end
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

    # add itk on all current campaign activities
    def add_itk_on_activities
      begin
        activities = Activity.of_campaign(current_campaign)
      rescue
        notify_error(:no_activities_present)
        return redirect_to(params[:redirect] || { action: :index })
      end
      if activities.any?
        ItkImportJob.perform_later(activity_ids: activities.pluck(:id), current_campaign: current_campaign, user: current_user)
      else
        notify_error(:no_activities_present)
        redirect_to(params[:redirect] || { action: :index })
      end
    end

    def compute_pfi_report
      campaign = Campaign.find_by(id: params[:campaign_id]) || current_campaign
      activities = if params[:id]
                     Activity.where(id: params[:id])
                   else
                     Activity.actives
                             .of_campaign(campaign)
                             .of_families(PLANT_FAMILY_ACTIVITIES)
                             .with_production_nature
                   end
      PfiReportJob.perform_later(campaign, activities.pluck(:id), current_user)
      notify_success(:document_in_preparation)
      redirect_path = params[:id] ? backend_activity_path(activities.first) : backend_activities_path
      redirect_to redirect_path
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

    def generate_budget
      @activity = Activity.find(params[:id])
      budget = @activity.budgets.find_by(campaign: current_campaign)
      return if Preference.find_by(name: 'ItkImportJob_running').present?

      if @activity.technical_workflow(current_campaign).present? || ( ( @activity.vine_farming? || @activity.animal_farming? ) && @activity.technical_sequence.present? ) || ( @activity.auxiliary? && MasterBudget.of_family(@activity.family).any?)
        ItkImportJob.perform_later(activity_ids: [@activity.id], current_campaign: current_campaign, user: current_user)
      else
        notify_warning(:no_reference_budget_found)
        redirect_to action: :show
      end
    end

    def traceability_xslx_export
      return unless @activity = find_and_check

      campaigns = Campaign.where(id: params[:campaign_id])
      InterventionExportJob.perform_later(activity_id: @activity.id, campaign_ids: campaigns.pluck(:id), user: current_user)
      notify_success(:document_in_preparation)
      redirect_to backend_activity_path(@activity)
    end

    def global_costs_xslx_export
      return unless @activity = find_and_check

      campaigns = Campaign.where(id: params[:campaign_id])
      GlobalCostExportJob.perform_later(activity_id: @activity.id, campaign_ids: campaigns.pluck(:id), user: current_user)
      notify_success(:document_in_preparation)
      redirect_to backend_activity_path(@activity)
    end

    private

      def open_activity
        @campaign = Campaign.find_by(name: params[:campaign][:name])
        current_user.current_campaign = @campaign
        current_user.current_period = Date.new(@campaign.harvest_year).to_s
        @activity.budgets.find_or_create_by!(campaign: @campaign)
      end
  end
end
