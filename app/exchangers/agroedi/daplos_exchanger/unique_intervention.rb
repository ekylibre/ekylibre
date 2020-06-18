module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class UniqueIntervention < DaplosIntervention
      node_name :intervention

      def self.regroup(_ints)
       # NOOP: These ones are not groupable
      end

      def inputs_to_register
        parameter_natures = {
          'sowing_without_plant_output' => :inputs,
          'harvesting_with_plant_or_land_parcel' => :outputs
        }.with_indifferent_access

        parameters_to_import = parameter_natures[procedure.name]
        unless parameters_to_import
          raise "Can't handle #{procedure.name} for unique interventions"
        end

        parameters_to_import
      end
    end
  end
end
