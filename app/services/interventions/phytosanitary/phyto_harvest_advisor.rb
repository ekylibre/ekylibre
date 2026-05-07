# frozen_string_literal: true

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

      # Bulk variant of {#reentry_possible?}/{#harvest_possible?} that batches DB
      # access for many targets. Returns {target_id => Models::HarvestResult}.
      def reentry_possible_for(targets, date, date_end: nil, ignore_intervention: nil)
        bulk_compute(targets, date, date_end, ignore_intervention) do |period, interventions|
          reentry_possible_from_interventions?(period, interventions)
        end
      end

      def harvest_possible_for(targets, date, date_end: nil, ignore_intervention: nil)
        bulk_compute(targets, date, date_end, ignore_intervention) do |period, interventions|
          harvest_possible_from_interventions?(period, interventions)
        end
      end

      def get_interventions_from_target(target, ignore_intervention)
        targets = get_product_id_from_target(target)

        interventions = get_spraying_intervention_on(targets)

        if ignore_intervention.present?
          interventions = interventions.where.not(id: ignore_intervention.id)
        end

        interventions
      end

      # because we don't know if the plant is closed or not
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
          .of_nature_using_phytosanitary
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

      private

        def bulk_compute(targets, date, date_end, ignore_intervention)
          int_period = Models::Period.new(date, date_end)
          results = {}

          targets.each do |target|
            unless target.is_a?(::Plant) || target.is_a?(::LandParcel)
              results[target.id] = Models::HarvestResult.new(true)
            end
          end
          valid_targets = targets.select { |t| t.is_a?(::Plant) || t.is_a?(::LandParcel) }

          if valid_targets.empty?
            return results
          end

          product_ids_per_target = preload_product_ids_per_target(valid_targets)
          all_product_ids = product_ids_per_target.values.flatten.uniq

          if all_product_ids.empty?
            valid_targets.each { |t| results[t.id] = compute_result(int_period, []) }
            return results
          end

          interventions_scope = get_spraying_intervention_on(all_product_ids).includes(:inputs)
          interventions_scope = interventions_scope.where.not(id: ignore_intervention.id) if ignore_intervention.present?
          interventions_by_id = interventions_scope.index_by(&:id)

          interventions_per_product_id = Hash.new { |h, k| h[k] = [] }
          if interventions_by_id.any?
            InterventionTarget
              .where(intervention_id: interventions_by_id.keys, product_id: all_product_ids)
              .pluck(:intervention_id, :product_id)
              .each { |int_id, prod_id| interventions_per_product_id[prod_id] << int_id }
          end

          valid_targets.each do |target|
            int_ids = product_ids_per_target[target.id].flat_map { |pid| interventions_per_product_id[pid] }.uniq
            interventions = int_ids.map { |id| interventions_by_id[id] }.compact
            results[target.id] = yield int_period, interventions
          end

          results
        end

        def preload_product_ids_per_target(targets)
          plants = targets.select { |t| t.is_a?(::Plant) }
          parcels = targets.select { |t| t.is_a?(::LandParcel) }

          ActiveRecord::Associations::Preloader.new.preload(plants + parcels, :activity_production) if (plants + parcels).any?

          ap_ids = parcels.map { |p| p.activity_production&.id }.compact.uniq
          plant_ids_per_ap = if ap_ids.any?
                               Plant.where(activity_production_id: ap_ids)
                                    .pluck(:activity_production_id, :id)
                                    .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(ap_id, pid), acc| acc[ap_id] << pid }
                             else
                               {}
                             end

          targets.each_with_object({}) do |target, acc|
            if target.is_a?(::Plant)
              support_id = target.activity_production&.support_id
              acc[target.id] = [target.id, support_id].compact
            else # LandParcel
              ap_id = target.activity_production&.id
              acc[target.id] = [target.id, *(ap_id ? plant_ids_per_ap.fetch(ap_id, []) : [])]
            end
          end
        end
    end
  end
end
