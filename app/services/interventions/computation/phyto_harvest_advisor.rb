module Interventions
  module Computation
    class PhytoHarvestAdvisor
      class HarvestResult
        attr_reader :possible, :next_possible_date

        def initialize(possible, next_possible_date = nil)
          @possible = possible
          @next_possible_date = next_possible_date
        end
      end

      def harvest_possible?(target, date, date_end: nil, ignore_intervention: nil)
        date_end ||= date

        if target.is_a?(::Plant)
          plant = [target.id]
          parcel = target.production.nil? ? [] : [target.production.support_id]
        elsif target.is_a?(::LandParcel)
          parcel = [target.id]
          plant = target.activity_production.nil? ? [] : Plant.where(activity_production_id: target.activity_production.id).pluck(:id)
        else
          return HarvestResult.new(true)
        end

        interventions = Intervention.where(id: InterventionTarget.where(product_id: [*plant, *parcel]).pluck(:intervention_id)).of_nature("spraying")
        if ignore_intervention.present?
          interventions = interventions.where.not(id: ignore_intervention.id)
        end

        issues_interventions = interventions.select { |i| i.inputs.any? { |input| input.allowed_harvest_factor.present? } }
              .select do |int|
                forbidden_start = int.stopped_at
                forbidden_end = int.stopped_at + int.inputs.map { |i| i.allowed_harvest_factor || 0 }.max.days

                date <= forbidden_start && forbidden_start <= date_end ||
                  date <= forbidden_end && forbidden_end <= date_end ||
                  forbidden_start <= date && date_end <= forbidden_end
              end

        issue_date = issues_interventions.map { |intervention| intervention.stopped_at + intervention.inputs.map { |input| input.allowed_harvest_factor }.compact.max.days }.max

        possible = issue_date.nil? || date > issue_date
        HarvestResult.new(possible, issue_date)
      end

      def reentry_possible?(target, date, date_end: nil, ignore_intervention: nil)
        date_end ||= date

        if target.is_a?(::Plant)
          plant = [target.id]
          parcel = target.production.nil? ? [] : [target.production.support_id]
        elsif target.is_a?(::LandParcel)
          parcel = [target.id]
          plant = target.activity_production.nil? ? [] : Plant.where(activity_production_id: target.activity_production.id).pluck(:id)
        else
          return HarvestResult.new(true)
        end

        interventions = Intervention.where(id: InterventionTarget.where(product_id: [*plant, *parcel]).pluck(:intervention_id)).of_nature("spraying")
        if ignore_intervention.present?
          interventions = interventions.where.not(id: ignore_intervention.id)
        end

        issues_interventions = interventions.select { |i| i.inputs.any? { |input| input.allowed_entry_factor.present? } }
              .select do |int|
                forbidden_start = int.stopped_at
                forbidden_end = int.stopped_at + int.inputs.map { |i| i.allowed_entry_factor || 0 }.max.hours

                date <= forbidden_start && forbidden_start <= date_end ||
                  date <= forbidden_end && forbidden_end <= date_end ||
                  forbidden_start <= date && date_end <= forbidden_end
              end

        issues_interventions = issues_interventions.select { |i| i.inputs.any? { |input| input.allowed_entry_factor.present? } }
        issue_time = issues_interventions.map { |intervention| intervention.stopped_at + intervention.inputs.map { |input| input.allowed_entry_factor }.compact.max.hours }.max

        possible = issue_time.nil? || date > issue_time
        HarvestResult.new(possible, issue_time)
      end
    end
  end
end
