module Interventions
  module Computation
    class PhytoHarvestAdvisor
      class HarvestResult
        attr_reader :possible, :next_possible_date

        def initialize(possible, next_possible_date)
          @possible = possible
          @next_possible_date = next_possible_date
        end
      end

      def harvest_possible?(target, date)
        interventions = Intervention.where(id: InterventionTarget.where(product: target).map { |it| it.intervention_id }).of_nature("spraying")
        issues_interventions = interventions.select { |i| i.inputs.any? { |input| input.allowed_harvest_factor.present? } }
        issue_date = issues_interventions.map { |intervention| intervention.stopped_at + intervention.inputs.map { |input| input.allowed_harvest_factor }.compact.max.days }.max

        possible = issue_date.nil? || date > issue_date
        HarvestResult.new(possible, issue_date)
      end

      def reentry_possible?(target, date)
        interventions = Intervention.where(id: InterventionTarget.where(product: target).map { |it| it.intervention_id }).of_nature("spraying")
        issues_interventions = interventions.select { |i| i.inputs.any? { |input| input.allowed_entry_factor.present? } }
        issue_time = issues_interventions.map { |intervention| intervention.stopped_at + intervention.inputs.map { |input| input.allowed_entry_factor }.compact.max.hours }.max

        possible = issue_time.nil? || date > issue_time
        HarvestResult.new(possible, issue_time)
      end
    end
  end
end
