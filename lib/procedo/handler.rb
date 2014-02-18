module Procedo
  class Handler

    @@method_parser = ::Procedo::HandlerMethodParser.new

    def initialize(variable, element = nil)
      @variable = variable
      if element.is_a?(Hash)
      else
        @method = @@method_parser.parse(element.attr('method').to_s)
        unless @indicator = Nomen::Indicators[element.attr('indicator').to_s]
          raise InvalidHandler, "Handler must have a valid 'indicator' attribute. Got: #{element.attr('indicator').inspect}"
        end
        if @indicator.datatype == :measure
          if element.has_attribute?("unit")
            unless @unit = Nomen::Units[element.attr('unit').to_s]
              raise InvalidHandler, "Handler must have a valid 'unit' attribute. Got: #{element.attr('unit').inspect}"
            end
          else
            @unit = @indicator.unit
          end
        end
      end
    end

    def procedure
      @variable.procedure
    end

    def short_name
      if @unit
        "#{@indicator.name}-#{@unit.name}"
      else
        @indicator.name
      end
    end

    # Returns the human name of the handler
    def human_name
      if @unit
        :indicator_with_unit.tl(indicator: @indicator.human_name, unit: @unit.symbol)
      else
        @indicator.human_name
      end
    end

  end
end
