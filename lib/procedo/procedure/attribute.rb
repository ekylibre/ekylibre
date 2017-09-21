module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Attribute < Procedo::Procedure::Setter
      TYPES = %i[derivative_of variety variant new_name working_zone new_container new_group new_variant killable identification_number].freeze

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        return if TYPES.include?(@name)
        raise "Unknown attribute type for #{procedure_name}/#{parameter_name}: " + @name.inspect
      end
    end
  end
end
