module Procedo
  module Errors

    class MissingAttribute < StandardError
    end

    class MissingVariable < StandardError
    end

    class MissingProcedure < StandardError
    end

    class MissingRole < StandardError
    end

    class NotUniqueIdentifier < StandardError
    end

    class UnknownProcedureNature < StandardError
    end

    class UnknownRole < StandardError
    end

    class InvalidExpression < StandardError
    end

    class InvalidHandler < StandardError
    end

    class AmbiguousExpression < InvalidExpression
    end

    class UnavailableReading < StandardError
    end

  end
end
