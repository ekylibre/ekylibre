module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    attr_reader :children

    def check
      daplos?
    end

    def import
      raise ActiveExchanger::NotWellFormedFileError unless daplos?
      crops = daplos&.interchange&.crops
      raise ActiveExchanger::NotWellFormedFileError unless crops

      #+1 to account for the regrouping
      w.count = crops.flat_map(&:interventions).compact.count

      @children = {}
      crops.each do |c|
        DaplosExchanger::Crop.new(self, c).tap(&:register)
      end
      DaplosExchanger::DaplosIntervention.regroup(interventions)

      @children[:crops].each(&:import)

      regroup_interventions!
    end

    def interventions
      @children[:crops].flat_map { |crop| crop.children[:interventions] }.compact
    end

    private

      def daplos
        @daplos = SVF::EdiDaplos2.parse(file)
      rescue SVF::InvalidSyntax
        return false
      end
      alias_method :daplos?, :daplos

      #TODO: Do this as pre-import work instead of destroying interventions
      def regroup_interventions!
        saved_interventions = interventions.map(&:record).uniq

        # Grouping criterion
        merge_groups = saved_interventions.group_by do |int|
          [int.procedure_name,
           int.working_periods.first.started_at,
           int.targets.pluck(:product_id)]
        end

        # Reducing each group to one intervention each
        merge_groups.each do |_criterion, to_be_merged|
          to_be_merged.reduce do |merged_into, other_intervention|
            # Switch old inputs to the new intervention
            other_intervention.inputs.each do |input|
              input.tap(&:reload).update(intervention_id: merged_into.id)
            end

            # Merge GUIDs to ensure we don't lose history
            merged_providers = merged_into.providers || {}
            merged_guids = merged_providers['daplos_intervention_guid'] || []
            other_providers = other_intervention.providers || {}

            merged_guids += other_providers['daplos_intervention_guid'] || []

            merged_into.inputs.reload
            merged_providers.merge!('daplos_intervention_guid' => merged_guids)
            merged_into.tap(&:reload).update!(providers: merged_providers)

            other_intervention.tap(&:reload).destroy
            merged_into.tap(&:reload)
          end
        end
        w.check_point
      end
  end
end
