module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Attribute < Procedo::Procedure::Setter
      TYPES = [:new_name, :working_zone].freeze

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        unless TYPES.include?(@name)
          fail "Unknown attribute type for #{procedure_name}/#{parameter_name}: " + @name.inspect
        end
      end
    end
  end
end
