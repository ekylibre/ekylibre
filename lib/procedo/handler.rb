module Procedo
  class Handler

    @@method_parser = ::Procedo::HandlerMethodParser.new

    def initialize(variable, element)
      @variable = variable
      @method = @@method_parser.parse(element.attr('method'))
    end

    def procedure
      @variable.procedure
    end

  end
end
