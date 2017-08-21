# require 'procedo/cardinality'

module Procedo
  class Procedure
    # Parameter class is the base class for all parameters types
    class Parameter
      attr_reader :procedure, :name, :group
      attr_accessor :cardinality

      delegate :name, to: :procedure, prefix: true

      def initialize(procedure, name, options = {})
        @procedure = procedure
        @name = name.to_sym
        @group = options[:group]
        @cardinality = Procedo::Cardinality.new(options[:cardinality] || '+')
      end

      def name=(value)
        # TODO: Check name unicity
        @name = value.to_sym
      end

      # Translate the name of the parameter
      def human_name(options = {})
        "procedure_parameters.#{name}".t(options.merge(default: ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize]))
      end

      def self.type
        @type ||= name.demodulize.underscore
      end

      def type
        self.class.type
      end

      def reflection_name
        self.class.type.pluralize
      end

      def inspect
        "<#{self.class.name} #{procedure_name}##{name}>"
      end

      def position
        procedure.position_of(self)
      end

      def display_status
        nil
      end

      def beta?
        false
      end

      # Returns +true+ if self depend on given parameter through a formula
      # of handlers, attributes or readings.
      def depend_on?(_parameter_name)
        false
      end
    end
  end
end
