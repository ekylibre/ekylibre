module Interventions
  module Phytosanitary
    class MaxApplicationValidator < ProductApplicationValidator
      attr_reader :targets_and_shape, :intervention_to_ignore, :intervention_stopped_at

      # @param [Array<Models::TargetAndShape>] targets_and_shape
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
      # @return [Maybe<Integer>]
      def compute_usage_application(product)
        campaign = Campaign.find_by(harvest_year: intervention_stopped_at.year)

        if campaign.present?
          interventions_with_same_phyto = get_interventions_with_same_phyto(product, campaign)

          candidates = select_with_shape_intersecting(interventions_with_same_phyto, get_targeted_zones)
          candidates = candidates.reject { |int| int == intervention_to_ignore } if intervention_to_ignore.present?

          Some(candidates.size)
        else
          None()
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

            if usage.nil? || (usage.applications_count == 1 && usage.applications_frequency.present?)
              result.vote_unknown(product)
            elsif usage.applications_count.present?
              max_applications = usage.applications_count
              maybe_applications = compute_usage_application(product)

              if maybe_applications.is_none?
                result.vote_unknown(product)
              elsif maybe_applications.get >= max_applications
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
