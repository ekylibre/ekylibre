# require 'procedo/procedure/parameter'

module Procedo
  module Engine
    class Set
      delegate :map, :collect, to: :parameters

      def initialize(intervention, parameter)
        fail 'Invalid intervention' unless intervention.is_a?(Procedo::Engine::Intervention)
        @intervention = intervention
        fail 'Invalid parameter reference' unless parameter.is_a?(Procedo::Procedure::Parameter)
        @parameter = parameter
      end

      def parameters
        @intervention.parameters_of_name(@parameter.name)
      end
    end
  end
end
