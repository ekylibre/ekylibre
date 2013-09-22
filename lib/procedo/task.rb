module Procedo

  class Task
    attr_reader :expression, :operation

    def initialize(operation, element)
      @operation = operation
      @expression = element.attr("do")
    end

  end

end
