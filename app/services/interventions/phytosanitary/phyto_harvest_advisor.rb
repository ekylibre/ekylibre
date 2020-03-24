module Interventions
  module Phytosanitary
    class PhytoHarvestAdvisor

      # @param [Plant, LandParcel] target
      # @param [DateTime] date
      # @option [DateTime] date_end
      # @option [Intervention] ignore_intervention
      # @return [Models::HarvestResult]
      def harvest_possible?(target, date, date_end: nil, ignore_intervention: nil)
        return Models::HarvestResult.new(true) if !target.is_a?(::Plant) && !target.is_a?(::LandParcel)

        interventions = get_interventions_from_target(target, ignore_intervention)

        int_period = Models::Period.new(date, date_end)

        harvest_possible_from_interventions?(int_period, interventions)
      end

      # @param [Plant, LandParcel] target
      # @param [DateTime] date
      # @option [DateTime] date_end
      # @option [Intervention] ignore_intervention
      # @return [Models::HarvestResult]
      def reentry_possible?(target, date, date_end: nil, ignore_intervention: nil)
        return Models::HarvestResult.new(true) if !target.is_a?(::Plant) && !target.is_a?(::LandParcel)

        interventions = get_interventions_from_target(target, ignore_intervention)

        int_period = Models::Period.new(date, date_end)

        reentry_possible_from_interventions?(int_period, interventions)
      end

      def get_interventions_from_target(target, ignore_intervention)
        targets = get_product_id_from_target(target)

        interventions = get_spraying_intervention_on(targets)

        if ignore_intervention.present?
          interventions = interventions.where.not(id: ignore_intervention.id)
        end

        interventions
      end

      #because we don't know if the plant is closed or not
      def entry_factor_fix_for_closed_usage(duration)
        if duration == 6.hours
          8.hours
        else
          duration
        end
      end

      # @param [Period] period
      # @param [Array<Intervention>] interventions
      # @return [Models::HarvestResult]
      def reentry_possible_from_interventions?(period, interventions)
        forbidden_periods = interventions.map { |i| Models::Period.new(i.stopped_at, (i.stopped_at + entry_factor_fix_for_closed_usage(i.inputs.map(&:allowed_entry_factor).compact.max || 0))) }
        compute_result(period, forbidden_periods)
      end

      # @param [Period] period
      # @param [Array<Intervention>] interventions
      # @return [Models::HarvestResult]
      def harvest_possible_from_interventions?(period, interventions)
        forbidden_periods = interventions.map { |i| Models::Period.new(i.stopped_at, (i.stopped_at + (i.inputs.map(&:allowed_harvest_factor).compact.max || 0))) }
        compute_result(period, forbidden_periods)
      end

      def get_product_id_from_target(target)
        plant = parcel = []

        if target.is_a?(::Plant)
          plant = [target.id]
          parcel = target.production.nil? ? [] : [target.production.support_id]
        elsif target.is_a?(::LandParcel)
          parcel = [target.id]
          plant = target.activity_production.nil? ? [] : Plant.where(activity_production_id: target.activity_production.id).pluck(:id)
        end

        [*plant, *parcel]
      end

      def get_spraying_intervention_on(targets)
        Intervention
          .where(id: InterventionTarget.where(product_id: targets).pluck(:intervention_id))
          .of_nature("spraying")
          .joins(:inputs) # inner join removes interventions without inputs
          .distinct
      end

      def select_periods_intersecting(period, periods)
        periods.select { |f_period| period.intersect?(f_period) }
      end

      # @param [Period] int_period
      # @param [Array<Period>] forbidden_periods
      # @return [Models::HarvestResult]
      def compute_result(int_period, forbidden_periods)
        periods = select_periods_intersecting(int_period, forbidden_periods)

        if periods.empty?
          Models::HarvestResult.new(true)
        else
          period = max_period(periods)
          Models::HarvestResult.new(false, period)
        end
      end

      def max_period(periods)
        periods.reduce { |p1, p2| p1.end_date >= p2.end_date ? p1 : p2 }
      end
    end
  end
end
