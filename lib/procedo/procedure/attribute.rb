module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Attribute < Procedo::Procedure::Setter
      TYPES = [:new_name, :working_zone, :variety, :derivative_of, :new_container, :new_group, :killable, :merge_stocks, :new_variant, :variant].freeze

      def initialize(parameter, name, options = {})
        @overloadable = options[:allow_overload]
        super(parameter, name, options)
        return if TYPES.include?(@name)
        raise "Unknown attribute type for #{procedure_name}/#{parameter_name}: " + @name.inspect
      end

      def can_be_overloaded?
        @overloadable.present?
      end

      def properties_hash
        case @name
        when /merge_stocks/ then { with: nil }
        else { dynascope: scope_hash }
        end
      end
    end
  end
end
