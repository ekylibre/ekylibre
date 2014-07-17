module Procedo

  class Handler

    attr_reader :name, :unit, :indicator, :converters, :widget, :usability_tree

    def initialize(variable, element = nil)
      @variable = variable
      # Extract attributes from XML element
      unless element.is_a?(Hash)
        element = %w(forward backward indicator unit to datatype name widget converters if).inject({}) do |hash, attr|
          if attr == 'converters'
            hash[:converters] = element.xpath('xmlns:converter').to_a
          elsif element.has_attribute?(attr)
            hash[attr.to_sym] = element.attr(attr)
          end
          hash
        end
      end

      # Check indicator
      unless @indicator = Nomen::Indicators[element[:indicator]]
        raise Procedo::Errors::InvalidHandler, "Handler of #{@variable.name} must have a valid 'indicator' attribute. Got: #{element[:indicator].inspect}"
      end

      # Get and check measure unit
      if @indicator.datatype == :measure
        if element.has_key?(:unit)
          unless @unit = Nomen::Units[element[:unit]]
            raise Procedo::Errors::InvalidHandler, "Handler must have a valid 'unit' attribute. Got: #{element[:unit].inspect}"
          end
        else
          @unit = @indicator.unit
        end
      end

      # Set name
      name = element[:name].to_s
      if name.blank?
        name = @indicator.name.dup
        if @unit and @variable.handlers.detect{|h| h.name.to_s == name}
          name << "_in_#{@unit.name}"
        end
      end
      @name = name.to_sym

      # Collect converters
      @converters = []
      if element[:converters] and element[:converters].any?
        for converter in element[:converters]
          @converters << Converter.new(self, converter)
        end
      else
        element[:to] ||= @indicator.name
        converter = {to: element[:to].to_sym}
        converter[:forward]  = (element[:forward].blank?  ? "value" : element[:forward])
        converter[:backward] = (element[:backward].blank? ? "value" : element[:backward])
        @converters << Converter.new(self, converter)
      # else
      #   raise Procedo::Errors::InvalidHandler, "Handler #{unique_name} (in #{procedure.name}) must have one converter at least with attribute 'to' or <converter> tags."
      end

      if element[:if]
        begin
          @usability_tree = HandlerMethod.parse(element[:if].to_s, root: "boolean_expression")
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{element.inspect}) #{variable.procedure.name} has a syntax error on usability test (if): #{e.message}"
        end
      end

      # Define widget
      @widget = (element[:widget] || (@indicator.datatype == :geometry ? :map : :number)).to_sym
    end

    def procedure
      @variable.procedure
    end

    def unit?
      !@unit.nil?
    end

    def destinations
      converters.map(&:destination).uniq
    end

    def check_usability?
      !@usability_tree.nil?
    end

    # def destination_unique_name
    #   "#{@variable.name}_#{destination}"
    # end

    # Returns the unique name of an handler inside a given procedure
    def unique_name
      "#{@variable.name}-#{name}"
    end

    # Unique identifier for a given handler
    def uid
      "#{self.procedure.name}-#{unique_name}"
    end

    def datatype
      @indicator.datatype
    end

    # Returns other handlers in the current variable scope
    def others
      @variable.handlers.select{|h| h != self }
    end

    # Returns the human name of the handler
    def human_name
      default, params = [], {indicator: indicator.human_name}
      if unit?
        default << :indicator_with_unit
        params[:unit] = unit.symbol
      end
      default << @indicator.human_name
      return "procedure_handlers.#{name}".t(params.merge(default: default))
    end

    def backward_converters
      converters.select(&:backward?)
    end

    def forward_converters
      converters.select(&:forward?)
    end


    # Returns keys
    def depend_on?(variable_name, mode = nil)
      self.converters.each do |converter|
        return true if converter.depend_on?(variable_name, mode)
      end
      return false
    end

    def forward_depend_on?(variable_name)
      depend_on?(variable_name, :forward)
    end

    def backward_depend_on?(variable_name)
      depend_on?(variable_name, :backward)
    end

  end
end
