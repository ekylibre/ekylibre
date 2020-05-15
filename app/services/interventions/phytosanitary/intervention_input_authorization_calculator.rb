module Interventions
  module Phytosanitary
    class InterventionInputAuthorizationCalculator
      class << self

        # @param [Intervention] intervention
        # @return [InterventionInputAuthorizationCalculator]
        def for_intervention(intervention)
          targets_and_shape = ::Interventions::Phytosanitary::Models::TargetAndShape.from_intervention(intervention)

          new(::Interventions::Phytosanitary::ValidatorCollectionValidator.build(targets_and_shape, intervention_to_ignore: intervention, intervention_started_at: intervention.started_at, intervention_stopped_at: intervention.stopped_at))
        end
      end

      attr_reader :validator

      # @param [ValidatorCollectionValidator] validator
      def initialize(validator)
        @validator = validator
      end

      # @param [InterventionInput] intervention_input
      # @param [Intervention] intervention
      # @return [Array{Symbol, Array<String>}]
      def authorization_state(intervention_input, intervention)
        products_usages = ::Interventions::Phytosanitary::Models::ProductWithUsage.from_intervention(intervention)
        data = @validator.validate(products_usages)
        [data.product_vote(intervention_input.product), data.product_messages(intervention_input.product)]
      end
    end
  end
end
