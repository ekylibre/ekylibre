module Interventions
  module Phytosanitary
    class OrganicMentionsValidator < ProductApplicationValidator
      # @param [Array<Plant, LandParcel>] targets
      attr_reader :targets

      # @param [Array<Plant, LandParcel>] targets
      def initialize(targets:)
        @targets = targets
      end

      def organic?
        @targets
          .map(&:activity)
          .compact.uniq
          .any?(&:organic_farming?)
      end

      # @param [RegisteredPhytosanitaryProduct, InterventionParameter::LoggedPhytosanitaryProduct] phyto
      # @return [Boolean]
      def allowed_for_organic_farming?(phyto)
        phyto.present? && phyto.allowed_for_organic_farming?
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets.empty?
          products_usages.each { |pu| result.vote_unknown(pu.product) }
        elsif organic?
          products_usages
            .reject { |pu| allowed_for_organic_farming?(pu.phyto) }
            .each { |pu| result.vote_forbidden(pu.product, :not_allowed_for_organic_farming.tl) }
        end

        result
      end
    end
  end
end
