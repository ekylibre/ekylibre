# require 'procedo/procedure/parameter'

module Procedo
  module Engine
    class Set
      attr_reader :parameter

      delegate :name, to: :parameter, prefix: true
      delegate :map, :collect, :each, to: :parameters

      def initialize(intervention, parameter, list = nil)
        raise 'Invalid intervention' unless intervention.is_a?(Procedo::Engine::Intervention)
        @intervention = intervention
        raise 'Invalid parameter reference' unless parameter.is_a?(Procedo::Procedure::Parameter)
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
