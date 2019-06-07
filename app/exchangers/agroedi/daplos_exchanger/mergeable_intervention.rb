module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class MergeableIntervention < DaplosIntervention
      node_name :intervention

      def self.regroup(interventions)
        to_merge = interventions.group_by do |intervention|
          [
            #TODO: There must be a better key than only started_at
            intervention.children[:working_periods].map(&:started_at),
            intervention.children[:inputs],
            intervention.procedure.name
          ]
        end
        to_merge.each do |_crit, group|
          group.reduce do |merged_in, intervention|
            # - Inputs cover all targets bc they're in area_unit
            # so no need to merge.
            # - Working periods are identical so no need to merge
            # - MergeableInterventins don't have outputs
            # => Only merging Targets and GUIDs
            intervention.children[:targets].each do |target|
              target.tap(&:unregister).register(to: merged_in)
            end
            merged_in.guids << intervention.guid
            # Removing intervention from the import
            intervention.unregister.tap { intervention.exchanger.w.check_point }
          end
        end
      end

      def inputs_to_register
        :inputs
      end
    end
  end
end
