module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Setter < Procedo::Procedure::Field
      code_trees :condition, root: 'boolean_expression'
      code_trees :default_value
      code_trees :compute_filter

      attr_reader :computations
      attr_accessor :computed_filter, :filter

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        @hidden = !!options[:hidden]
        self.default_value = options[:default_value]
        self.condition = options[:if]

        if options[:compute_filter]
          self.compute_filter = options[:compute_filter]
        end
        @filter = options[:filter]

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

      # Returns scope hash for unroll
      def scope_hash
        hash = {}
        hash[:of_expression] = @filter unless @filter.nil?
        hash[:of_expression] = @computed_filter unless @computed_filter.nil?
        hash
      end
    end
  end
end
