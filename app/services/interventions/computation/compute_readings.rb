module Interventions
  module Computation
    class ComputeReadings
      def initialize(engine_intervention)
        @engine_intervention = engine_intervention
      end

      def perform
        @engine_intervention.procedure.each_parameter do |parameter|
          @engine_intervention.parameters_of_name(parameter.name).each do |root_product_parameter|
            if root_product_parameter.is_a? Procedo::Engine::Intervention::GroupParameter
              compute_group_parameter_readings(root_product_parameter)
            else
              compute_parameter_readings(root_product_parameter)
            end
          end
        end
      end

      def compute_group_parameter_readings(root_product_parameter)
        root_product_parameter.each_member do |product_parameter|
          compute_parameter_readings(product_parameter)
        end
      end

      def compute_parameter_readings(product_parameter)
        return if product_parameter.reference.readings.empty?
        product_parameter.reference.readings.each_with_index do |ref_reading, i|
          next if product_parameter.readings.any? { |_index, r| r.name.to_s == ref_reading.name.to_s }
          product_parameter.add_reading(i, indicator_name: ref_reading.name)
        end
      end

    end
  end
end
