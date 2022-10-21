# frozen_string_literal: true

module Interventions
  module Phytosanitary
    class ValidatorCollectionValidator
      class << self
        # @param [Array<Models::TargetZone>] targets_zone
        # @option [Intervention, nil] intervention_to_ignore
        # @option [DateTime, nil] intervention_started_at
        # @option [DateTime, nil] intervention_stopped_at
        # @return [ValidatorCollectionValidator]
        def build(targets_zone, intervention_to_ignore: nil, intervention_started_at: nil, intervention_stopped_at: nil)
          targets = targets_zone.map { |element| element.target }
          dose_computation = RegisteredPhytosanitaryUsageDoseComputation.build

          ::Interventions::Phytosanitary::ValidatorCollectionValidator.new(
            ::Interventions::Phytosanitary::MixCategoryCodeValidator.new,
            ::Interventions::Phytosanitary::AquaticBufferValidator.new,
            ::Interventions::Phytosanitary::ProductStateValidator.new,
            ::Interventions::Phytosanitary::ApplicationFrequencyValidator.new(
              targets_zone: targets_zone,
              ignored_intervention: intervention_to_ignore,
              intervention_started_at: intervention_started_at,
              intervention_stopped_at: intervention_stopped_at
            ),
            ::Interventions::Phytosanitary::OrganicMentionsValidator.new(targets: targets),
            ::Interventions::Phytosanitary::DoseValidationValidator.new(
              targets_zone: targets_zone,
              unit_converter: ::Interventions::ProductUnitConverter.new
            ),
            ::Interventions::Phytosanitary::MaxApplicationValidator.new(
              targets_zone: targets_zone,
              intervention_to_ignore: intervention_to_ignore,
              intervention_stopped_at: intervention_stopped_at
            ),
            ::Interventions::Phytosanitary::NonTreatmentAreasValidator.new(targets_zone: targets_zone)
          )
        end
      end

      # @param [Array<ProductApplicationValidator>] children
      def initialize(*children)
        @children = children
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        @children
          .map { |c| c.validate(products_usages) }
          .reduce { |acc, result| acc.merge(result) }
      end
    end
  end
end
