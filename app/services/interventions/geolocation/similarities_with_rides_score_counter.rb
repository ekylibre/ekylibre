# frozen_string_literal: true

module Interventions
  module Geolocation
    # Calculate similarity score bewtween rides and interventions
    class SimilaritiesWithRidesScoreCounter
      attr_reader :intervention

      def initialize(intervention:, rides:)
        @intervention = intervention
        @rides = rides
      end

      # @return [<Integer>] total score
      def total_score
        [localization_score, equipment_score, date_score].sum
      end

      # @return [<Integer>] Similarity score for cultivable zones
      def localization_score
        (targets_cultivable_zone_ids & rides_cultivable_zone_ids).length
      end

      # @return [<Integer>] Similarity score for equipment
      def equipment_score
        intervention_equipment_ids = intervention.tools.pluck(:product_id).uniq
        ride_equipment_ids = rides.pluck(:product_id).uniq
        (intervention_equipment_ids & ride_equipment_ids).length
      end

      # @return [<Integer>] Similarity score for started_at date
      def date_score
        date_difference = main_ride.started_at - intervention.started_at
        -Measure.new(date_difference, :second).convert(:day).value.to_i.abs
      end

      private
        attr_reader :rides

        def main_ride
          @rides.first
        end

        def targets_cultivable_zone_ids
          CultivableZone.joins(:activity_productions).all
            .merge(ActivityProduction.where(id: intervention.targets.collect(&:best_activity_production)))
            .pluck(:id).uniq
        end

        def rides_cultivable_zone_ids
          CultivableZone.joins(:rides).all.merge(rides).pluck(:id).uniq
        end

    end
  end
end
