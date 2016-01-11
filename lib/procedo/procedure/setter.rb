module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Setter < Procedo::Procedure::Field
      code_trees :default_value, :condition

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        @hidden = !!options[:hidden]
        self.default_value = options[:default_value]
        self.condition = options[:condition]
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
    end
  end
end
