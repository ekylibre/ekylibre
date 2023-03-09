# frozen_string_literal: true

module TechnicalItineraries
  module Itk
    class ImportItkFromLexiconService
      attr_reader :activities, :campaign, :log_result

      def initialize(activity_ids:, campaign: )
        @activities = Activity.where(id: activity_ids)
        @campaign = campaign
        @log_result = {}
      end

      def perform
        if @activities.nil? || @campaign.nil?
          init_param_error
          return
        end

        @log_result[:count_tw_created] = 0
        @log_result[:count_no_tw_exists] = 0
        @log_result[:count_tw_already_exists] = 0

        # I - import Lexicon ITK into Ekylibre technical_itinerary who match Ekylibre activities
        ApplicationRecord.transaction do
          @activities.main.reorder(:name).each do |activity|

            # 0 - check if activity have already a default ITK by using tactics
            at = ActivityTactic.find_by(activity_id: activity.id, campaign_id: @campaign.id, default: true)
            if at
              @log_result[:count_tw_already_exists] += 1
            end

            # 0 - temp variable
            temp_pn = ProductNature.first

            #####################################################
            # technical_workflow (TW) for main annual activity  #
            #####################################################
            if activity.main? && activity.annual? && activity.plant_farming?

              # 10 - find a default TW in lexicon by activity attributes
              tw = find_technical_workflow(activity, at)

              if at && at.technical_itinerary
                # 50 - Update AP activity_productions and activity
                update_activity_productions_with_ti(activity, at.technical_itinerary, at)
              elsif tw
                # 11- create AT with link to TW
                creation_service = TechnicalItineraries::Itk::CreateTactic.new(activity: activity, technical_workflow: tw, campaign: @campaign)
                at = creation_service.create_or_update_activity_tactic

                # 12 - create TI with link to AT
                ti = find_or_create_technical_itinerary(at, activity)

                # 20 - create intervention template (IT) link to TI for each TechnicalWorkflowProcedure (TWP) in TW
                tiit_ids = creation_service.create_procedures_and_intervention_templates(ti, temp_pn)

                # 50 - Update AP activity_productions and activity
                update_activity_productions_with_ti(activity, ti, at, tw)

                # 51 - compute_day_between_intervention
                TechnicalItineraryInterventionTemplate.where(id: tiit_ids).each(&:compute_day_between_intervention)

                # log
                @log_result[:count_tw_created] += 1
              else
                @log_result[:count_no_tw_exists] += 1
              end
            # technical_workflow_sequence for perennial
            elsif activity.main? && activity.perennial? && activity.vine_farming?
              # 10 - find a default TW in lexicon by activity attributes
              ts = find_technical_sequence(activity, at)
              plain_prod_tw_id = ts.sequences.reorder(:year_start).last.technical_workflow_id
              if ts
                # 11- create AT with link to TW
                creation_service = TechnicalItineraries::Itk::CreateTactic.new(activity: activity, technical_sequence: ts, campaign: @campaign)
                at = creation_service.create_or_update_activity_tactic

                # 12 - create TI with link to AT
                tis = find_or_create_technical_itineraries(at, activity)
                tis.each do |ti|
                  # 20 - create intervention template (IT) link to TI for each TechnicalWorkflowProcedure (TWP) in TW
                  tiit_ids = creation_service.create_procedures_and_intervention_templates(ti, temp_pn)

                  # 50 - Update AP activity_productions and activity for PP only
                  if ti.technical_workflow_id == plain_prod_tw_id
                    update_plain_prod_activity_productions_with_ti(activity, ti, ti.technical_workflow, at)
                  end

                  # 51 - compute_day_between_intervention
                  TechnicalItineraryInterventionTemplate.where(id: tiit_ids).each(&:compute_day_between_intervention)

                  # log
                  @log_result[:count_tw_created] += 1
                end
              else
                @log_result[:count_no_tw_exists] += 1
              end
            # technical_workflow_sequence for animal
            elsif activity.main? && activity.perennial? && activity.animal_farming?
              # 10 - find a default TW in lexicon by activity attributes
              ts = find_technical_sequence(activity, at)
              plain_prod_tw_id = ts.sequences.reorder(:year_start).last.technical_workflow_id
              if ts
                # 11- create AT with link to TW
                creation_service = TechnicalItineraries::Itk::CreateTactic.new(activity: activity, technical_sequence: ts, campaign: @campaign)
                at = creation_service.create_or_update_activity_tactic
                # 12 - create TI with link to AT
                tis = find_or_create_technical_itineraries(at, activity)
                tis.each do |ti|
                  # 20 - create intervention template (IT) link to TI for each TechnicalWorkflowProcedure (TWP) in TW
                  tiit_ids = creation_service.create_procedures_and_intervention_templates(ti, temp_pn)

                  # 50 - Update AP activity_productions and activity for PP only
                  if ti.technical_workflow_id == plain_prod_tw_id
                    update_plain_prod_activity_productions_with_ti(activity, ti, ti.technical_workflow, at)
                  end

                  # 51 - compute_day_between_intervention
                  TechnicalItineraryInterventionTemplate.where(id: tiit_ids).each(&:compute_day_between_intervention)
                  # log
                  @log_result[:count_tw_created] += 1
                end
              else
                @log_result[:count_no_tw_exists] += 1
              end
            end
          end

          # PLANT_FARMING II - create scenario for current campaign
          # find or create scenario and destroy previous scenario_activities
          plant_farming_annual_scenario = Scenario.find_or_create_by(campaign: @campaign, name: "#{:plant_farming.tl} | #{@campaign.harvest_year}")
          # create scenario and plot for activities
          @activities.reorder(:name).each do |activity|
            # create plot scenario for plant farming activities
            next if activity.auxiliary? || activity.animal_farming? || activity.perennial?

            old_scenario_activities = plant_farming_annual_scenario.scenario_activities.where(activity: activity)
            old_scenario_activities.destroy_all if old_scenario_activities.any?

            creation_budget_service = TechnicalItineraries::Itk::CreateBudget.new(activity: activity, scenario: plant_farming_annual_scenario, campaign: @campaign)

            creation_budget_service.create_item_activity_for_scenario
            creation_budget_service.create_budget_from_itk
          end

          # VINE_FARMING II - create scenario for current campaign
          # find or create scenario and destroy previous scenario_activities
          vine_farming_annual_scenario = Scenario.find_or_create_by(campaign: @campaign, name: "#{:vine_farming.tl} | #{@campaign.harvest_year}")
          vine_farming_annual_scenario.scenario_activities.destroy_all if vine_farming_annual_scenario.scenario_activities.any?
          # create scenario and plot for activities
          @activities.where(family: 'vine_farming').reorder(:name).each do |activity|
            creation_budget_service = TechnicalItineraries::Itk::CreateBudget.new(activity: activity, scenario: vine_farming_annual_scenario, campaign: @campaign)
            creation_budget_service.create_item_activity_for_scenario
            creation_budget_service.create_budget_from_itk
          end

          # ANIMAL_FARMING II - create scenario for current campaign
          # find or create scenario and destroy previous scenario_activities
          animal_farming_annual_scenario = Scenario.find_or_create_by(campaign: @campaign, name: "#{:animal_farming.tl} | #{@campaign.harvest_year}")
          animal_farming_annual_scenario.scenario_activities.destroy_all if animal_farming_annual_scenario.scenario_activities.any?
          # create scenario and plot for activities
          @activities.where(family: 'animal_farming').reorder(:name).each do |activity|
            creation_budget_service = TechnicalItineraries::Itk::CreateBudget.new(activity: activity, scenario: animal_farming_annual_scenario, campaign: @campaign)
            creation_budget_service.create_item_activity_for_scenario
            creation_budget_service.create_budget_from_itk
          end

          # III - create budget item for each activity in Ekylibre from
          # Ekylibre technical_itinerary corresponding to scenario plot daily charges
          @activities.auxiliary.reorder(:name).each do |aux_activity|
            creation_aux_budget_service = TechnicalItineraries::Itk::CreateAuxiliaryBudget.new(activity: aux_activity, campaign: @campaign)
            creation_aux_budget_service.create_budget_from_lexicon
          end
          # IV - create budget item for auxiliary activity in Ekylibre from Lexicon charges
        end
      end

      def success?
        @error.nil?
      end

      def fail?
        !@error.nil?
      end

      private

        # 10 - find a default TW in lexicon by activity attributes
        def find_technical_workflow(activity, at)
          if at && at.technical_workflow
            at.technical_workflow
          else
            activity_reference_name = activity.reference_name
            tw_by_att = TechnicalWorkflow.of_family(activity.family).of_production(activity_reference_name).where(production_system: (activity.production_system_name || 'intensive_farming'), life_cycle: activity.production_cycle)
            if tw_by_att.any?
              tw_by_att.first
            else
              nil
            end
          end
        end

        # 10 - find a default TW in lexicon by activity attributes
        def find_technical_sequence(activity, at)
          if at && at.technical_sequence
            at.technical_sequence
          else
            activity_reference_name = activity.reference_name
            ts_by_att = TechnicalSequence.of_family(activity.family).of_production(activity_reference_name).where(production_system: (activity.production_system_name || 'intensive_farming'))
            if ts_by_att.any?
              ts_by_att.first
            else
              nil
            end
          end
        end

        def find_or_create_technical_itinerary(at, activity)
          TechnicalItinerary.import_from_lexicon_with_activity_and_campaign(campaign: @campaign, activity: activity, technical_workflow_id: at.technical_workflow_id)
        end

        def find_or_create_technical_itineraries(at, activity)
          tis = []
          TechnicalWorkflowSequence.where(technical_sequence_id: at.technical_sequence_id).each do |tws|
            if ti = TechnicalItinerary.find_by(campaign: @campaign, activity: activity, technical_workflow_id: tws.technical_workflow_id)
              tis << ti
            else
              tis << TechnicalItinerary.import_from_lexicon_with_activity_and_campaign(campaign: @campaign, activity: activity, technical_workflow_id: tws.technical_workflow_id)
            end
          end
          tis
        end

        # update activity production with ti and predicated_sowing_date with start date of tw
        def update_activity_productions_with_ti(activity, ti, at, tw = nil)
          aps = ActivityProduction.where(activity_id: activity.id, campaign_id: @campaign.id)
          aps.each do |ap|
            if tw
              p_sowing_date = Date.new(ap.started_on.year, tw.start_month, tw.start_day)
            elsif at && at.planned_on
              p_sowing_date = at.planned_on
            else
              p_sowing_date = ap.started_on
              at.planned_on ||= ap.started_on
            end
            ap.technical_itinerary_id = ti.id
            ap.predicated_sowing_date = ((ap.started_on > p_sowing_date || ap.stopped_on < p_sowing_date) ? ap.started_on : p_sowing_date)
            ap.save!
          end
          activity.use_tactics = true
          activity.save!
          at.technical_itinerary_id = ti.id
          at.save!
        end

        # update activity production with ti and predicated_sowing_date with start date of tw
        def update_plain_prod_activity_productions_with_ti(activity, ti, tw, at)
          # select only ap in plain production
          aps = activity.productions.where('starting_year <= ?', @campaign.harvest_year)
          aps.each do |ap|
            p_start_date = Date.new((@campaign.harvest_year + ap.production_started_on_year), tw.start_month, tw.start_day)
            ap.technical_itinerary_id = ti.id
            ap.predicated_sowing_date = p_start_date
            ap.save!
          end
          activity.use_tactics = true
          activity.save!
          at.technical_itinerary_id = ti.id
          at.save!
        end

        def fail!(error)
          @error = error
        end

        def init_param_error
          fail!('Activities param is missing') if @activities.nil?
          fail!('Campaign param is missing') if @campaign.nil?
        end

    end
  end
end
