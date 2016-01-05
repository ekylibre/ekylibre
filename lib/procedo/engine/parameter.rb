require 'procedo/engine/intervention'

module Procedo
  module Engine
    class Parameter
      attr_reader :name, :intervention, :id, :reference, :type

      delegate :procedure, to: :intervention
      delegate :name, to: :reference, prefix: true

      def initialize(intervention, id, attributes = {})
        unless intervention.is_a?(Procedo::Engine::Intervention)
          fail "Invalid intervention: #{intervention.inspect}"
        end
        @intervention = intervention
        @attributes = attributes.symbolize_keys
        puts @attributes.inspect.yellow
        @id = id
        unless root?
          @name = @attributes[:reference_name].to_sym
          @reference = procedure.find!(@name)
          @type = @reference.type
        end
      end

      def root?
        @id == Procedo::Procedure::ROOT_NAME
      end

      def to_hash
        fail NotImplementedError
      end

      def param_name
        "#{type.to_s.pluralize}_attributes".to_sym
      end
    end
  end
end
