module Interventions
  module Phytosanitary
    class ApplicationFrequencyValidator
      attr_reader :targets_and_shape, :intervention_stopped_at

      # @param [Array<Models::TargetAndShape>] targets_and_shape
      # @option [DateTime, nil] intervention_stopped_at
      def initialize(targets_and_shape:, intervention_stopped_at: nil)
        @targets_and_shape = targets_and_shape
        @intervention_stopped_at = intervention_stopped_at
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets_and_shape.empty? || intervention_stopped_at.nil?
          products_usages.each { |pu| result.vote_unknown(pu.product) }
        else
          # @var [Hash<Symbol => Array<Models::ProductUsage>>] groups
          groups = products_usages.group_by { |pu| guess_vote(pu) }

          groups.fetch(:unknown, []).each { |pu| result.vote_unknown(pu.product) }
          groups.fetch(:forbidden, []).each { |pu| result.vote_forbidden(pu.product, :applications_interval_not_respected.tl) }
        end

        result
      end

      # @param [Models::ProductWithUsage] product_usage
      # @return [Symbol] :unknown, allowed, :forbidden
      def guess_vote(product_usage)
        usage = product_usage.usage
        product = product_usage.product
        phyto = product.phytosanitary_product

        if usage.nil? || product.france_maaid.blank? || phyto.nil?
          :unknown
        elsif usage.applications_frequency.nil? || interval_respected?(product_usage)
          :allowed
        else
          :forbidden
        end
      end

      # @param [Product] product
      # @return [Array<Intervention>]
      def get_interventions_with_same_phyto(product)
        current_campaign = Campaign.on(intervention_stopped_at)
        Intervention.of_campaigns(*[current_campaign, current_campaign.previous, current_campaign.following].compact)
                    .of_nature_using_phytosanitary
                    .with_input_of_maaids(product.france_maaid)
      end

      # @param [Array<Intervention>] interventions
      # @param [Array<Charta::Geometry>] zones
      # @return [Array<Intervention>]
      def select_with_shape_intersecting(interventions, zones)
        interventions.select do |intervention|
          intervention.targets.map(&:working_zone).any? { |wz| zones.any? { |shape| shape.intersects?(wz) } }
        end
      end

      # @param [DateTime] intervention_end
      # @param [RegisteredPhytosanitaryUsage] usage
      # @return [Models::Period]
      def build_intervention_period(intervention_end, usage)
        Models::Period.parse(intervention_end, intervention_end + usage.applications_frequency)
      end

      # @return [Array<Charta::Geometry>]
      def get_targeted_zones
        targets_and_shape.map(&:shape)
      end

      # @param [Models::ProductWithUsage] product_usage
      # @return [Array<Models::Period>]
      def forbidden_periods(product_usage)
        interventions_with_same_phyto = get_interventions_with_same_phyto(product_usage.product)
        intervention_same_phyto_and_zone = select_with_shape_intersecting(interventions_with_same_phyto, get_targeted_zones)

        intervention_same_phyto_and_zone.map do |int|
          build_intervention_period(int.stopped_at, product_usage.usage)
        end
      end

      # @param [Models::ProductWithUsage] product_usage
      # @return [Boolean]
      def interval_respected?(product_usage)
        f_period = build_intervention_period(intervention_stopped_at, product_usage.usage)
        int_periods = forbidden_periods(product_usage)

        int_periods.none? { |int_period| int_period.intersect?(f_period) }
      end
    end
  end
end
