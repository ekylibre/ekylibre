module Interventions
  module Computation
    class PhytoHarvestAdvisor
      class Period
        attr_reader :start_date, :end_date

        def initialize(start_date, end_date)
          @start_date = start_date
          @end_date = end_date || start_date
        end

        def intersect?(period)
          start_date <= period.start_date && period.start_date <= end_date ||
          start_date <= period.end_date && period.end_date <= end_date ||
          period.start_date <= start_date && end_date <= period.end_date
        end
      end

      class HarvestResult
        attr_reader :possible, :next_possible_date

        def initialize(possible, next_possible_date = nil)
          @possible = possible
          @next_possible_date = next_possible_date
        end
      end

      def harvest_possible?(target, date, date_end: nil, ignore_intervention: nil)
        return HarvestResult.new(true) if !target.is_a?(::Plant) && !target.is_a?(::LandParcel)


        interventions = get_interventions_from_target(target, ignore_intervention)

        int_period = Period.new(date, date_end)

        harvest_possible_from_interventions?(int_period, interventions)
      end

      def get_interventions_from_target(target, ignore_intervention)
        targets = get_product_id_from_target(target)

        interventions = get_spraying_intervention_on(targets)

        if ignore_intervention.present?
          interventions = interventions.where.not(id: ignore_intervention.id)
        end

        interventions
      end

      def reentry_possible?(target, date, date_end: nil, ignore_intervention: nil)
        return HarvestResult.new(true) if !target.is_a?(::Plant) && !target.is_a?(::LandParcel)

        interventions = get_interventions_from_target(target, ignore_intervention)

        int_period = Period.new(date, date_end)

        reentry_possible_from_interventions?(int_period, interventions)
      end

      def reentry_possible_from_interventions?(period, interventions)
        forbidden_periods = interventions.map { |int| Period.new(int.stopped_at, (int.stopped_at  + int.inputs.map { |i| i.allowed_entry_factor || 0 }.max.hours)) }
        compute_result(period, forbidden_periods)
      end

      def harvest_possible_from_interventions?(period, interventions)
        forbidden_periods = interventions.map { |int| Period.new(int.stopped_at, (int.stopped_at  + int.inputs.map { |i| i.allowed_harvest_factor || 0 }.max.days)) }
        compute_result(period, forbidden_periods)
      end

      def get_product_id_from_target(target)
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
        Intervention.where(id: InterventionTarget.where(product_id: targets).pluck(:intervention_id)).of_nature("spraying")
      end

      def select_periods_intersecting(period, periods)
        periods.select { |f_period| period.intersect?(f_period) }
      end


      def compute_result(int_period, forbidden_periods)
        periods = select_periods_intersecting(int_period, forbidden_periods)
        if periods.empty?
          HarvestResult.new(true)
        else
          issue_date = periods.map { |int| int.end_date }.max
          HarvestResult.new(false, issue_date)
        end
      end
    end
  end
end
