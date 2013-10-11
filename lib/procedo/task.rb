module Procedo

  class Task
    attr_reader :expression, :operation

    def initialize(operation, element)
      @operation = operation
      if element.has_attribute?("do")
        @expression = element.attr("do").to_s
      else
        raise MissingAttribute, "Attribute 'do' is mandatory"
      end
    end

    def procedure
      @operation.procedure
    end

    def human_expression
      return @expression
    end

  end

end
