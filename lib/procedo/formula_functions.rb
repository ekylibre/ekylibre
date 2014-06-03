module Procedo
  module FormulaFunctions

    class << self


      def area(shape)
        return shape.area.to_f(:square_meter)
      rescue
        raise FailedFunctionCall
      end


      def intersection(shape, other_shape)
        return shape.intersection(other_shape)
      rescue
        raise FailedFunctionCall
      end
      
      def members_count(group)
        return group.members_at.count.to_i if group.members_at
      rescue
        raise FailedFunctionCall
      end

      def contents_count(container)
        return container.containeds.select(&:available?).size
      rescue
        raise FailedFunctionCall
      end

    end
  end
end
