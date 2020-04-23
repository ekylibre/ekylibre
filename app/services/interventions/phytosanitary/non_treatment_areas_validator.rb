module Interventions
  module Phytosanitary
    class NonTreatmentAreasValidator < ProductApplicationValidator

      attr_reader :targets_and_shape

      # @param [Array<Models::TargetAndShape>] targets_and_shape
      def initialize(targets_and_shape:)
        @targets_and_shape = targets_and_shape
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets_and_shape.empty?
          products_usages.each { |pu| result.vote_unknown(pu.product) }
        else
          products_usages.each do |pu|
            if pu.usage.nil?
              result.vote_unknown(pu.product)
            elsif working_zone_overlapping_nta?(pu.usage, targets_and_shape)
              result.vote_forbidden(pu.product, :working_zone_overlaps_nta.tl)
            end
          end
        end

        result
      end

      private

        def working_zone_overlapping_nta?(usage, targets_and_shape)
          return false unless buffer = usage.untreated_buffer_aquatic

          shapes = targets_and_shape.map(&:shape)
          RegisteredHydroItem.buffer_intersecting(buffer, *shapes).any?
        end
    end
  end
end
