module Procedo
  module Engine
    class Input < ProductParameter
      def initialize(intervention, id, attributes = {})
        super(intervention, id, attributes)
        @quantity_handler = attributes[:quantity_handler]
      end

      def quantity_value=(value)
      end

      def quantity_unit_name=(unit_name)
        quantity_unit = Nomen::Unit.find(unit_name)
      end

      def quantity_unit
        @quantity_unit ||= Nomen::Unit.find(@quantity.unit)
      end

      def quantity_unit=(unit)
        if @quantity && quantity_unit && quantity_unit.dimension == unit.dimension
          @quantity_unit = nil
          @quantity.in!(unit.name)
        elsif @quantity_value && !quantity_unit
          @quantity = @quantity_value.in!(unit.name)
        end
      end
    end
  end
end
