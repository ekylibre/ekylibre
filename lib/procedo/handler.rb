module Procedo
  class Handler

    @@method_parser = ::Procedo::HandlerMethodParser.new
    @@whole_indicators = Nomen::Indicators.where(related_to: :whole).collect{|i| i.name.to_sym }

    attr_reader :unit, :indicator, :destination

    def initialize(variable, element = nil)
      @variable = variable
      # Extract attributes from XML element
      unless element.is_a?(Hash)
        element = %w(method indicator unit to).inject({}) do |hash, attr|
          if element.has_attribute?(attr)
            hash[attr.to_sym] = element.attr(attr)
          end
          hash
        end
      end
      element[:to] ||= element[:indicator]
      element[:to] = element[:to].to_sym
      unless @@whole_indicators.include?(element[:to])
        raise InvalidHandler, "Handler must have a valid destination (#{@@whole_indicators.to_sentence} expected, got #{element[:to]})"
      end
      @destination = element[:to]
      # Load values
      @method = @@method_parser.parse(element[:method].to_s)
      unless @indicator = Nomen::Indicators[element[:indicator]]
        raise InvalidHandler, "Handler must have a valid 'indicator' attribute. Got: #{element[:indicator].inspect}"
      end
      if @indicator.datatype == :measure
        if element.has_key?(:unit)
          unless @unit = Nomen::Units[element[:unit]]
            raise InvalidHandler, "Handler must have a valid 'unit' attribute. Got: #{element[:unit].inspect}"
          end
        else
          @unit = @indicator.unit
        end
      end
    end

    def procedure
      @variable.procedure
    end

    def unit?
      !@unit.nil?
    end

    # Returns the unique name of an handler inside a given procedure
    def unique_name
      "#{@variable.name}-#{short_name}"
    end

    def destination_unique_name
      "#{@variable.name}_#{destination}"
    end

    # Unique identifier for a given handler
    def uid
      "#{self.procedure.namespace}-#{procedure.short_name}-#{procedure.flat_version}-#{self.unique_name}"
    end

    def short_name
      if unit?
        "#{@indicator.name}-#{@unit.name}"
      else
        @indicator.name
      end
    end

    def name
      if unit?
        "#{@indicator.name}_#{@unit.name}"
      else
        @indicator.name
      end
    end

    # Returns other handlers in the current variable scope
    def others
      @variable.handlers.select{|h| h != self }
    end


    # Returns the human name of the handler
    def human_name
      if unit?
        :indicator_with_unit.tl(indicator: @indicator.human_name, unit: @unit.symbol)
      else
        @indicator.human_name
      end
    end

  end
end
