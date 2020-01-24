module Interventions
  module Computation
    class RemoveCustomProcedureReadings
      def initialize(engine_intervention)
        @engine_intervention = engine_intervention
      end

      def perform
        @engine_intervention.procedure.parameters.each do |param|
          type = param.type.to_s
          next if param.class == Procedo::Procedure::GroupParameter
          next if param.readings.empty?
          if param.group.name != :root_
            next if Constants::PERMITTED_READINGS[:group_parameter].keys.exclude?(type) 
            param.readings.each do |reading|
              param.remove_reading(reading.name) if Constants::PERMITTED_READINGS[:group_parameter][type].include?(reading.name.to_s)
            end
          else
            next if Constants::PERMITTED_READINGS.keys.exclude?(type)
            param.readings.each do |reading|
              param.remove_reading(reading.name) if Constants::PERMITTED_READINGS[type].include?(reading.name.to_s)
            end
          end
        end
      end
    end
  end
end

