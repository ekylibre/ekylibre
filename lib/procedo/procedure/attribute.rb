module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Attribute < Procedo::Procedure::Setter
      TYPES = %i[new_name working_zone new_container new_group new_variant killable identification_number usage_id allowed_entry_factor allowed_harvest_factor].freeze

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        unless TYPES.include?(@name)
          raise "Unknown attribute type for #{procedure_name}/#{parameter_name}: " + @name.inspect
        end
      end
    end
  end
end
