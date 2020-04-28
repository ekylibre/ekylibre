module Interventions
  module Phytosanitary
    class InterventionInputAuthorizationCalculator
      class << self

        # @param [Intervention] intervention
        # @return [InterventionInputAuthorizationCalculator]
        def for_intervention(intervention)
          targets_and_shape = ::Interventions::Phytosanitary::Models::TargetAndShape.from_intervention(intervention)

          new(::Interventions::Phytosanitary::ValidatorCollectionValidator.build(targets_and_shape, intervention_to_ignore: intervention, intervention_stopped_at: intervention.stopped_at))
        end
      end

      attr_reader :validator

      # @param [ValidatorCollectionValidator] validator
      def initialize(validator)
        @validator = validator
      end

      # @param [InterventionInput] intervention_input
      # @return [Array{Symbol, Array<String>}]
      def authorization_state(intervention_input)
        product_usage = ::Interventions::Phytosanitary::Models::ProductWithUsage.from_intervention_input(intervention_input)
        data = @validator.validate([product_usage])
        [data.product_vote(product_usage.product), data.product_messages(product_usage.product)]
      end
    end
  end
end
