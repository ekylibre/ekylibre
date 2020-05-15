module Interventions
  module Phytosanitary
    class MaxApplicationValidator < ProductApplicationValidator
      attr_reader :targets_and_shape, :intervention_to_ignore, :intervention_stopped_at

      # @params [Array<Models::TargetAndShape>] targets_and_shape
      # @option [Intervention, nil] intervention_to_ignore
      # @option [DateTime, nil] intervention_stopped_at
      def initialize(targets_and_shape:, intervention_to_ignore: nil, intervention_stopped_at: nil)
        @targets_and_shape = targets_and_shape
        @intervention_to_ignore = intervention_to_ignore
        @intervention_stopped_at = intervention_stopped_at
      end

      # @return [Array<Charta::Geometry>]
      def get_targeted_zones
        targets_and_shape.map(&:shape)
      end

      # @param [Product] product
      # @return [Integer]
      def compute_usage_application(product)
        interventions_with_same_phyto = get_interventions_with_same_phyto(product, Campaign.on(intervention_stopped_at))

        candidates = select_with_shape_intersecting(interventions_with_same_phyto, get_targeted_zones)
        candidates = candidates.reject { |int| int == intervention_to_ignore } if intervention_to_ignore.present?

        candidates.size
      end

      # @param [Integer] applications
      # @param [Integer] max_applications
      # @return [Boolean]
      def application_forbidden?(applications, max_applications:)
        if intervention_to_ignore.nil?
          applications >= max_applications
        else
          applications > max_applications
        end
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets_and_shape.empty? || intervention_stopped_at.nil?
          products_usages.each do |product_usage|
            result.vote_unknown(product_usage.product)
          end
        else
          products_usages.each do |product_usage|
            product = product_usage.product
            usage = product_usage.usage

            if usage.nil?
              result.vote_unknown(product)
            elsif usage.applications_count.present?
              max_applications = usage.applications_count
              applications = compute_usage_application(product)

              if application_forbidden?(applications, max_applications: max_applications)
                result.vote_forbidden(product, :applications_count_bigger_than_max.tl, on: :usage)
              end
            end
          end
        end

        result
      end
    end
  end
end
