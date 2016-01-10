module Procedo
  module Errors
    class MissingAttribute < Error
    end

    class MissingVariable < Error
    end

    class MissingProcedure < Error
    end

    class MissingRole < Error
    end

    class NotUniqueIdentifier < Error
    end

    class UnknownProcedureNature < Error
    end

    class UnknownAspect < Error
    end

    class UnknownHandler < Error
    end

    class UnknownRole < Error
    end

    class UnknownVariable < Error
    end

    class InvalidExpression < Error
    end

    class InvalidHandler < Error
    end

    class AmbiguousExpression < InvalidExpression
    end

    class UncomputableFormula < Error
    end

    class UnavailableReading < UncomputableFormula
    end

    class FailedFunctionCall < UncomputableFormula
    end
  end
end
