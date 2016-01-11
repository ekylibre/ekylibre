module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Setter < Procedo::Procedure::Field
      code_trees :condition, root: 'boolean_expression'
      code_trees :default_value

      attr_reader :computations

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        @hidden = !!options[:hidden]
        self.default_value = options[:default_value]
        self.condition = options[:if]
        @computations = []
      end

      # Returns true if setter can be accessed by a human during recording
      # process.
      def accessible?
        !@hidden
      end

      def hidden?
        @hidden
      end

      def depend_on?(parameter_name)
        default_value_with_parameter?(parameter_name) ||
          condition_with_parameter?(parameter_name)
      end

      def add_computation(expression, destinations, options = {})
        @computations << Procedo::Procedure::Computation.new(@parameter, expression, options.merge(expression: expression, destinations: destinations))
      end
    end
  end
end
