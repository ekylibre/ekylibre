module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Reading < Procedo::Procedure::Setter
      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        unless Nomen::Indicator.find(@name)
          raise "Unknown reading type for #{procedure_name}/#{parameter_name}: " + @name.inspect
        end
      end
    end
  end
end
