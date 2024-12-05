# frozen_string_literal: true

module Interventions
  module Participations
    class BuildParticipationService
      attr_reader :intervention

      def initialize(intervention: nil)
        @intervention = intervention
      end

      def perform(product: nil, state: nil, working_periods: [])
        @intervention
          .participations
          .build(product: product,
                 intervention: @intervention,
                 state: state,
                 procedure_name: @intervention.procedure_name,
                 working_periods: working_periods)
      end
    end
  end
end
