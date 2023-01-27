# frozen_string_literal: true

module TechnicalItineraries
  module Itk
    class ImportItkFromLexiconService
      attr_reader :activities, :campaign, :log_result

      def initialize(activity_ids:, campaign: )
        @activities = Activity.where(id: activity_ids)
        @campaign = campaign
        @log_result = {}
        @logger ||= Logger.new(File.join(Rails.root, 'log', "itk-#{@campaign.name}-#{Ekylibre::Tenant.current.to_s}.log"))
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
          @logger.info("---------------------------------------------------------------")
          @logger.info("---------------------------------------------------------------")
          @logger.info("Start on #{@activities.count} main activities for #{@campaign.name}")
          @activities.main.reorder(:name).each do |activity|

            # 0 - check if activity have already a default ITK by using tactics
            at = ActivityTactic.find_by(activity_id: activity.id, default: true)
            if at
              @log_result[:count_tw_already_exists] += 1
            end

            # 0 - temp variable
            temp_pn = ProductNature.first

            #####################################################
            # technical_workflow (TW) for main annual activity  #
            #####################################################
            if activity.main? && activity.annual? && activity.plant_farming?
              @logger.info("####################################################")
              @logger.info("               ITK Plant Annual for #{activity.name}")
              @logger.info("####################################################")

              # 10 - find a default TW in lexicon by activity attributes
              tw = find_technical_workflow(activity, at)

              if tw
                # 11- create AT with link to TW
                creation_service = TechnicalItineraries::Itk::CreateTactic.new(activity: activity, technical_workflow: tw, campaign: @campaign)
                at = creation_service.create_or_update_activity_tactic
                @logger.info("11 - AT : #{at.name}")

                # 12 - create TI with link to AT
                ti = find_or_create_technical_itinerary(at, activity)
                @logger.info("12 - TI : #{ti.name}")

                # 20 - create intervention template (IT) link to TI for each TechnicalWorkflowProcedure (TWP) in TW
                tiit_ids = creation_service.create_procedures_and_intervention_templates(ti, temp_pn)

                # 50 - Update AP activity_productions and activity
                update_activity_productions_with_ti(activity, ti, tw, at)
                @logger.info("50 - activity productions updated with TI #{ti.id}")

                # 51 - compute_day_between_intervention
                TechnicalItineraryInterventionTemplate.where(id: tiit_ids).each do |tiit_to_c|
                  tiit_to_c.compute_day_between_intervention
                  @logger.info("_51 - TIIT updated with compute_day_between_intervention : #{tiit_to_c.day_between_intervention}")
                end

                # log
                @log_result[:count_tw_created] += 1
              else
                @logger.error("10 - TW : no TW exist for #{activity.name}")
                @log_result[:count_no_tw_exists] += 1
              end
            # technical_workflow_sequence for perennial
            elsif activity.main? && activity.perennial? && activity.vine_farming?
              @logger.info("####################################################")
              @logger.info("               ITK Vine Perennial for #{activity.name}")
              @logger.info("####################################################")
              # 10 - find a default TW in lexicon by activity attributes
              ts = find_technical_sequence(activity, at)
              plain_prod_tw_id = ts.sequences.reorder(:year_start).last.technical_workflow_id
              if ts
                # 11- create AT with link to TW
                creation_service = TechnicalItineraries::Itk::CreateTactic.new(activity: activity, technical_sequence: ts, campaign: @campaign)
                at = creation_service.create_or_update_activity_tactic
                @logger.info("11 - AT : #{at.name}")

                # 12 - create TI with link to AT
                tis = find_or_create_technical_itineraries(at, activity)
                @logger.info("12 - TIS : #{tis.map(&:name)}")
                tis.each do |ti|
                  # 20 - create intervention template (IT) link to TI for each TechnicalWorkflowProcedure (TWP) in TW
                  tiit_ids = creation_service.create_procedures_and_intervention_templates(ti, temp_pn)

                  # 50 - Update AP activity_productions and activity for PP only
                  if ti.technical_workflow_id == plain_prod_tw_id
                    update_plain_prod_activity_productions_with_ti(activity, ti, ti.technical_workflow, at)
                    @logger.info("50 - activity productions in PP updated with TI corresponding to PP #{ti.id}")
                  end

                  # 51 - compute_day_between_intervention
                  TechnicalItineraryInterventionTemplate.where(id: tiit_ids).each do |tiit_to_c|
                    tiit_to_c.compute_day_between_intervention
                    @logger.info("_51 - TIIT updated with compute_day_between_intervention : #{tiit_to_c.day_between_intervention}")
                  end

                  # log
                  @log_result[:count_tw_created] += 1
                end
              else
                @logger.error("10 - TS : no TS exist for #{activity.name}")
                @log_result[:count_no_tw_exists] += 1
              end
            end
          end

          # PLANT_FARMING II - create scenario for current campaign
          # find or create scenario and destroy previous scenario_activities
          plant_farming_annual_scenario = Scenario.find_or_create_by(campaign: @campaign, name: "#{:plant_farming.tl} | #{@campaign.harvest_year}")
          plant_farming_annual_scenario.scenario_activities.destroy_all if plant_farming_annual_scenario.scenario_activities.any?
          # create scenario and plot for activities
          @activities.reorder(:name).each do |activity|
            # create plot scenario for plant farming activities
            next if activity.auxiliary? || activity.animal_farming? || activity.perennial?

            @logger.info("####################################################")
            @logger.info("     SCENARIOS & BUDGETS for #{activity.name}")
            @logger.info("####################################################")

            creation_budget_service = TechnicalItineraries::Itk::CreateBudget.new(activity: activity, scenario: plant_farming_annual_scenario, campaign: @campaign)

            creation_budget_service.create_plot_activity_for_scenario
            creation_budget_service.create_budget_from_itk
          end

          # VINE_FARMING II - create scenario for current campaign
          # find or create scenario and destroy previous scenario_activities
          vine_farming_annual_scenario = Scenario.find_or_create_by(campaign: @campaign, name: "#{:vine_farming.tl} | #{@campaign.harvest_year}")
          vine_farming_annual_scenario.scenario_activities.destroy_all if vine_farming_annual_scenario.scenario_activities.any?
          # create scenario and plot for activities
          @activities.where(family: 'vine_farming').reorder(:name).each do |activity|

            @logger.info("####################################################")
            @logger.info("     SCENARIOS & BUDGETS for #{activity.name}")
            @logger.info("####################################################")

            creation_budget_service = TechnicalItineraries::Itk::CreateBudget.new(activity: activity, scenario: vine_farming_annual_scenario, campaign: @campaign)

            creation_budget_service.create_plot_activity_for_scenario
            creation_budget_service.create_budget_from_itk
          end

          # III - create budget item for each activity in Ekylibre from
          # Ekylibre technical_itinerary corresponding to scenario plot daily charges

          @logger.info("BUDGETS FOR ANIMAL ACTIVITY")
          @logger.info("BUDGETS FOR AUXILIARY ACTIVITY")
          @activities.auxiliary.reorder(:name).each do |aux_activity|
            @logger.info("####################################################")
            @logger.info("     AUXILIARY BUDGET for #{aux_activity.name}")
            @logger.info("####################################################")
            creation_aux_budget_service = TechnicalItineraries::Itk::CreateAuxiliaryBudget.new(activity: aux_activity, campaign: @campaign)
            creation_aux_budget_service.create_budget_from_lexicon
          end
          @logger.info("---------------------------------------------------------------")
          @logger.info("---------------------------------------------------------------")
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
            @logger.info("10 - SEARCH TW by specie : #{tw_by_att.count} TW found ")
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
            @logger.info("10 - SEARCH TS by specie : #{ts_by_att.count} TS found ")
            if ts_by_att.any?
              ts_by_att.first
            else
              nil
            end
          end
        end

        def find_or_create_technical_itinerary(at, activity)
          TechnicalItinerary.import_from_lexicon(campaign: @campaign, activity: activity, technical_workflow_id: at.technical_workflow_id)
        end

        def find_or_create_technical_itineraries(at, activity)
          tis = []
          TechnicalWorkflowSequence.where(technical_sequence_id: at.technical_sequence_id).each do |tws|
            if ti = TechnicalItinerary.find_by(campaign: @campaign, activity: activity, technical_workflow_id: tws.technical_workflow_id)
              tis << ti
            else
              tis << TechnicalItinerary.import_from_lexicon(campaign: @campaign, activity: activity, technical_workflow_id: tws.technical_workflow_id)
            end
          end
          tis
        end

        # update activity production with ti and predicated_sowing_date with start date of tw
        def update_activity_productions_with_ti(activity, ti, tw, at)
          aps = ActivityProduction.where(activity_id: activity.id, campaign_id: @campaign.id)
          aps.each do |ap|
            p_sowing_date = Date.new(ap.started_on.year, tw.start_month, tw.start_day)
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
