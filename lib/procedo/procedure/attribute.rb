module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Attribute < Procedo::Procedure::Field
      TYPES = [:name, :working_zone]

      code_trees :value, :default_value

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        unless TYPES.include?(@name)
          fail "Unknown attribute type for #{procedure_name}/#{parameter_name}: " + @name.inspect
        end
        self.value = options[:value]
        self.default_value = options[:default_value]
      end
    end
  end
end
