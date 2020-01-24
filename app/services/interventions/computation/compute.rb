# Permits to compute Intervention from a small set of parameters 
module Interventions
  module Computation
    class Compute
      attr_reader :intervention

      def initialize(parameters: {})
        @parameters = parameters
      end

      def perform(options: {})
        compute(@parameters.merge(options))
      end

      private

      def compute(attributes)
        # Extract readings from the attributes since procedo doesn't create readings when initialized
        readings = ExtractReadings.new(attributes).perform

        # Convert set of attributes from an array of hash to a hash with index in order to make Procedo to handle them
        attrs = ComputedParameters.new(@parameters).perform
        engine_intervention = Procedo::Engine.new_intervention(attrs)

        # Iterate over engine_intervention parameters in order to add reading to parameter which depend on it for calculation
        ComputeReadings.new(engine_intervention).perform

        # Enables to add the custom reading passed on the API payload and extracted before creating the procedo intervention
        AddCustomReadings.new(engine_intervention, readings).perform if readings.any?

        # Build 'html' selector which enables to recognize which part of the attributes needs to be updated
        UpdateEngineIntervention.new(engine_intervention, @parameters).perform

        attributes = attributes.merge(engine_intervention.to_attributes)
        # Readings added on references needs to be removed after merging attributes in order for the visual interface not to display additional fields
        RemoveCustomProcedureReadings.new(engine_intervention).perform if readings.any?

        attributes
      end
    end
  end
end
