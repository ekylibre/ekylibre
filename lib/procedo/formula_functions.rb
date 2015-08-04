module Procedo
  module FormulaFunctions
    class << self
      def area(shape)
        return shape.area.to_f(:square_meter)
      rescue
        raise Procedo::FailedFunctionCall
      end

      def intersection(shape, other_shape)
        return shape.intersection(other_shape)
      rescue
        raise Procedo::FailedFunctionCall
      end

      def members_count(group)
        if group.present?
          value = group.actor.members_at(group.now).count.to_i
          return (value > 0 ? value : 0)
        else
          return 0
        end
      rescue
        raise Procedo::FailedFunctionCall
      end

      def contents_count(container)
        return container.actor.containeds.count(&:available?)
      rescue
        raise Procedo::FailedFunctionCall
      end
    end
  end
end
