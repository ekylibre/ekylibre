# frozen_string_literal: true

module Interventions
  module Phytosanitary
    class NonTreatmentAreasValidator < ProductApplicationValidator
      attr_reader :targets_zone

      # @param [Array<Models::TargetZone>] targets_zone
      def initialize(targets_zone:)
        @targets_zone = targets_zone
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets_zone.empty?
          products_usages.each { |pu| result.vote_unknown(pu.product) }
        else
          products_usages.each do |pu|
            if pu.usage.nil?
              result.vote_unknown(pu.product)
            elsif working_zone_overlapping_nta?(pu.usage, targets_zone)
              result.vote_forbidden(pu.product, :working_zone_overlaps_nta.tl)
            end
          end
        end

        result
      end

      private

        def working_zone_overlapping_nta?(usage, targets_zone)
          return false unless buffer = usage.untreated_buffer_aquatic

          shapes = targets_zone.map(&:shape)
          RegisteredHydrographicItem.buffer_intersecting(buffer, *shapes).any?
        end
    end
  end
end
