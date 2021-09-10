# frozen_string_literal: true

module Interventions
  module Participations
    class FillEquipmentsParticipationsInteractor
      def self.call(params)
        interactor = new(params)
        interactor.run
        interactor
      end

      attr_reader :intervention_agents, :error

      def initialize(params)
        @intervention_agents = params[:intervention_agents]
      end

      def run
        @intervention_agents.each do |intervention_agent|
          intervention = intervention_agent.intervention
          # intervention_state = intervention.state

          next if intervention.nil?
          next unless intervention.auto_calculate_working_periods
          next unless intervention.valid?

          build_equipments_participations(intervention)

          # intervention.save!
          # intervention.update_column(:state, intervention_state)
        end
      end

      def success?
        @error.nil?
      end

      def fail?
        !@error.nil?
      end

      private

        def fail!(error)
          @error = error
        end

        def build_equipments_participations(intervention)
          intervention.tools.each do |intervention_tool|
            equipment = intervention_tool.product

            next if equipment_participation_exist?(intervention, equipment)

            working_duration_params = { intervention: intervention,
                                        participations: intervention.participations,
                                        product: equipment }

            natures = %i[travel intervention] if equipment.try(:tractor?)
            natures = %i[intervention] unless equipment.try(:tractor?)

            natures.each do |nature|
              build_equipment_participation(intervention, equipment, nature, working_duration_params)
            end
          end
        end

        def equipment_participation_exist?(intervention, equipment)
          participations_count = intervention
                                   .participations
                                   .select { |participation| participation.product_id == equipment.id }
                                   .count

          participations_count > 0
        end

        def build_equipment_participation(intervention, equipment, nature, working_duration_params)
          duration = InterventionWorkingTimeDurationCalculationService
                       .new(**working_duration_params)
                       .perform(nature: nature, modal: false)

          stopped_at = intervention.started_at + (duration * 60 * 60)

          working_periods = []
          working_periods << InterventionWorkingPeriod
                               .new(nature: nature,
                                    started_at: intervention.started_at,
                                    stopped_at: stopped_at)

          intervention
            .participations
            .create(product: equipment,
                    intervention: intervention,
                    state: :done,
                    procedure_name: intervention.procedure_name,
                    working_periods: working_periods)
        end
    end
  end
end
