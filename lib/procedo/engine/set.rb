# require 'procedo/procedure/parameter'

module Procedo
  module Engine
    # A set is a couple of data: reference parameter and its associated "real" data (products)
    class Set
      attr_reader :parameter

      delegate :name, to: :parameter, prefix: true
      delegate :map, :collect, :each, :size, :count, to: :parameters

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
        sub(list)
      end

      def first
        sub([@list.first])
      end

      private

      def sub(items)
        self.class.new(@intervention, @parameter, items)
      end
    end
  end
end
