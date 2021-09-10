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
          @logger.info("Start on #{@activities.count} activities for #{@campaign.name}")
          @activities.reorder(:name).each do |activity|
            # 0 - don't want auxiliary
            next if activity.auxiliary?

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
            if activity.main? && activity.annual?
              @logger.info("####################################################")
              @logger.info("               ITK for #{activity.name}")
              @logger.info("####################################################")

              # 10 - find a default TW in lexicon by activity attributes
              tw = find_technical_workflow(activity)

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
                update_activity_productions_with_ti(activity, ti, tw)
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
            elsif activity.main? && activity.perennial?
              @logger.error("No perennial ITK for the moment ! : #{activity.name}")
              @log_result[:count_no_tw_exists] += 1
            end
          end

          # II - create scenario for current campaign
          # find or create scenario and destroy previous scenario_activities
          plant_farming_annual_scenario = Scenario.find_or_create_by(campaign: @campaign, name: "GLOBAL-#{@campaign.harvest_year}")
          plant_farming_annual_scenario.scenario_activities.destroy_all if plant_farming_annual_scenario.scenario_activities.any?
          # create scenario and plot for activities
          @activities.reorder(:name).each do |activity|
            # create plot scenario for plant farming activities
            next if activity.auxiliary? || activity.animal_farming?

            @logger.info("####################################################")
            @logger.info("     SCENARIOS & BUDGETS for #{activity.name}")
            @logger.info("####################################################")

            creation_budget_service = TechnicalItineraries::Itk::CreateBudget.new(activity: activity, scenario: plant_farming_annual_scenario, campaign: @campaign)

            creation_budget_service.create_plot_activity_for_scenario
            creation_budget_service.create_budget_from_itk
          end

          # III - create budget item for each activity in Ekylibre from
          # Ekylibre technical_itinerary corresponding to scenario plot daily charges

          @logger.info("BUDGETS FOR ANIMAL ACTIVITY")
          @logger.info("BUDGETS FOR ADMINISTRATIVE ACTIVITY")
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
        def find_technical_workflow(activity)
          specie = activity.production_nature&.specie || activity.cultivation_variety
          tw_by_att = TechnicalWorkflow.of_family(activity.family).of_specie(specie).where(production_system: (activity.production_system_name || 'intensive_farming'), life_cycle: activity.production_cycle)
          @logger.info("10 - SEARCH TW by specie : #{tw_by_att.count} TW found ")
          if tw_by_att.any?
            tw_by_att.first
          else
            nil
          end
        end

        def find_or_create_technical_itinerary(at, activity)
          ti = TechnicalItinerary.find_or_create_by(campaign: @campaign, activity: activity, activity_tactic_id: at.id, name: at.name, description: 'Set by Lexicon')
        end

        # update activity production with ti and predicated_sowing_date with start date of tw
        def update_activity_productions_with_ti(activity, ti, tw)
          aps = ActivityProduction.where(activity_id: activity.id, campaign_id: @campaign.id)
          aps.each do |ap|
            p_sowing_date = Date.new(ap.started_on.year, tw.start_month, tw.start_day)
            ap.technical_itinerary_id = ti.id
            ap.predicated_sowing_date = ((ap.started_on > p_sowing_date || ap.stopped_on < p_sowing_date) ? ap.started_on : p_sowing_date)
            ap.save!
          end
          activity.use_tactics = true
          activity.save!
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
