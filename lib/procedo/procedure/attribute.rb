module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Attribute < Procedo::Procedure::Setter
      TYPES = [:derivative_of, :identification_number, :killable, :new_container,
               :new_group, :new_name, :new_variant, :variant, :variety, :working_zone].freeze

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        return if TYPES.include?(@name)
        raise "Unknown attribute type for #{procedure_name}/#{parameter_name}: " + @name.inspect
      end
    end
  end
end
