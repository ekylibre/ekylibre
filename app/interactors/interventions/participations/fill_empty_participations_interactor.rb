module Interventions
  module Participations
    class FillEmptyParticipationsInteractor
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
        begin
          @intervention_agents.each do |intervention_agent|
            intervention = intervention_agent.intervention
            intervention_state = intervention.state
            working_periods = build_working_periods(intervention: intervention)

            intervention
              .participations
              .build(product: intervention_agent.product,
                     intervention: intervention,
                     state: :done,
                     procedure_name: intervention.procedure_name,
                     working_periods: working_periods)

            has_equipment_participation = has_equipment_participation?(intervention)
            intervention.auto_calculate_working_periods = !has_equipment_participation

            unless has_equipment_participation
              build_equipments_participations(intervention)
            end

            intervention.save!
            intervention.update_column(:state, intervention_state)
          end
        rescue StandardError => exception
          fail!(exception.message)
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

      def build_working_periods(intervention: nil, nature: :intervention)
        return [] if intervention.nil?

        working_periods = []

        intervention.working_periods.each do |working_period|
          working_periods << InterventionWorkingPeriod
                               .new(nature: nature,
                                    started_at: working_period.started_at,
                                    stopped_at: working_period.stopped_at,
                                    duration: working_period.duration)
        end

        working_periods
          .reverse
      end

      def has_equipment_participation?(intervention)
        participations_count = intervention
                                 .participations
                                 .select { |participation| participation.product.is_a?(Equipment) }
                                 .count

        participations_count > 0
      end

      def build_equipments_participations(intervention)
        intervention.tools.each do |intervention_tool|
          working_duration_params = { intervention: intervention,
                                      participations: intervention.participations,
                                      product: intervention_tool.product }

          duration = InterventionWorkingTimeDurationCalculationService
                     .new(**working_duration_params)
                     .perform(nature: :intervention, modal: false)

          stopped_at = intervention.started_at + (duration * 60 * 60)

          working_periods = []
          working_periods << InterventionWorkingPeriod
                             .new(nature: :intervention,
                                  started_at: intervention.started_at,
                                  stopped_at: stopped_at)
          intervention
            .participations
            .build(product: intervention_tool.product,
                   intervention: intervention,
                   state: :done,
                   procedure_name: intervention.procedure_name,
                   working_periods: working_periods)
        end
      end
    end
  end
end