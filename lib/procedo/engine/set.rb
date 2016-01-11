# require 'procedo/procedure/parameter'

module Procedo
  module Engine
    class Set
      attr_reader :parameter

      delegate :name, to: :parameter, prefix: true
      delegate :map, :collect, to: :parameters

      def initialize(intervention, parameter, list = nil)
        fail 'Invalid intervention' unless intervention.is_a?(Procedo::Engine::Intervention)
        @intervention = intervention
        fail 'Invalid parameter reference' unless parameter.is_a?(Procedo::Procedure::Parameter)
        @parameter = parameter
        @list = list || @intervention.parameters_of_name(@parameter.name)
      end

      def parameters
        @list
      end

      def build(list = nil)
        self.class.new(@intervention, @parameter, list)
      end
    end
  end
end
