module Procedo
  class Procedure
    # A Computation defines an information computed to stored in given
    # destinations
    class Computation < Field
      code_trees :condition, root: 'boolean_expression',
                             context: :code_tree_context
      code_trees :expression

      attr_reader :destinations

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        @destinations = options[:destinations]
        self.expression = options[:expression]
        self.condition = options[:if]
      end
    end
  end
end
