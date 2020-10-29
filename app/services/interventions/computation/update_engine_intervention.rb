module Interventions
  module Computation
    class UpdateEngineIntervention
      def initialize(engine_intervention, parameters)
        @engine_intervention = engine_intervention
        @parameters = parameters
      end

      def perform
        updaters.each do |change|
          @engine_intervention.impact_with!(change)
        end
      end

      def updaters
        updaters = []

        updaters << group_parameters_selector if @parameters.key? 'group_parameters_attributes'
        updaters << parameters_selector

        updaters.flatten
      end

      def parameters_selector
        %i[product_id quantity_value].map { |attr| parameter_selector(attr) }
      end

      def parameter_selector(attribute)
        (Constants::PRODUCT_PARAMETERS & Constants::PARAMETER_ACCEPTED_TYPES[attribute]).map do |collection_name|
          (@parameters.fetch("#{collection_name}_attributes", {})).keys.map do |i|
            "#{collection_name}[#{i}]#{attribute}"
          end
        end
      end

      def group_parameters_selector
        @parameters['group_parameters_attributes'].map do |i, group_parameters|

          %i[product_id quantity_value].map { |attr| group_parameter_selector(attr, group_parameters, i) }
        end
      end

      def group_parameter_selector(attribute, group_parameters, index)
        (Constants::PRODUCT_PARAMETERS & Constants::GROUP_PARAMETER_ACCEPTED_TYPES[attribute]).map do |collection_name|
          (group_parameters.fetch("#{collection_name}_attributes", {})).keys.map do |j|
            "group_parameters[#{index}]#{collection_name}[#{j}]#{attribute}"
          end
        end
      end
    end
  end
end


