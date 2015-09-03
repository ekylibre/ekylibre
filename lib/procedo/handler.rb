module Procedo
  class Handler
    attr_reader :name, :unit, :indicator, :converters, :widget, :usability_tree, :attributes

    def initialize(variable, element = nil)
      @variable = variable
      # Extract attributes from XML element
      if element.is_a?(Hash)
        @attributes = element
      else
        @attributes = %w(forward backward indicator unit to datatype name widget converters if).inject({}) do |hash, attr|
          if attr == 'converters'
            hash[:converters] = element.xpath('xmlns:converter').to_a
          elsif element.has_attribute?(attr)
            hash[attr.to_sym] = element.attr(attr)
          end
          hash
        end
      end

      # Check indicator
      unless @indicator = Nomen::Indicator[@attributes[:indicator]]
        fail Procedo::Errors::InvalidHandler, "Handler of #{@variable.name} must have a valid 'indicator' attribute. Got: #{@attributes[:indicator].inspect}"
      end

      # Get and check measure unit
      if @indicator.datatype == :measure
        if @attributes.key?(:unit)
          unless @unit = Nomen::Unit[@attributes[:unit]]
            fail Procedo::Errors::InvalidHandler, "Handler must have a valid 'unit' attribute. Got: #{@attributes[:unit].inspect}"
          end
        else
          @unit = @indicator.unit
        end
      end

      # Set name
      name = @attributes[:name].to_s
      if name.blank?
        name = @indicator.name.dup
        if @unit && @variable.handlers.detect { |h| h.name.to_s == name }
          name << "_in_#{@unit.name}"
        end
      end
      @name = name.to_sym

      # Collect converters
      @converters = []
      if @attributes[:converters] && @attributes[:converters].any?
        for converter in @attributes[:converters]
          @converters << Converter.new(self, converter)
        end
      else
        @attributes[:to] ||= @indicator.name
        converter = { to: @attributes[:to].to_sym }
        converter[:forward]  = (@attributes[:forward].blank? ? 'value' : @attributes[:forward])
        converter[:backward] = (@attributes[:backward].blank? ? 'value' : @attributes[:backward])
        @converters << Converter.new(self, converter)
        # else
        #   raise Procedo::Errors::InvalidHandler, "Handler #{unique_name} (in #{procedure.name}) must have one converter at least with attribute 'to' or <converter> tags."
      end

      if @attributes[:if]
        begin
          @usability_tree = HandlerMethod.parse(@attributes[:if].to_s, root: 'boolean_expression')
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{@attributes.inspect}) #{variable.procedure.name} has a syntax error on usability test (if): #{e.message}"
        end
      end

      # Define widget
      @widget = (@attributes[:widget] || (@indicator.datatype == :geometry ? :map : :number)).to_sym
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
      "#{procedure.name}-#{unique_name}"
    end

    def datatype
      @indicator.datatype
    end

    # Returns other handlers in the current variable scope
    def others
      @variable.handlers.select { |h| h != self }
    end

    # Returns the human name of the handler
    def human_name
      default = []
      params = { indicator: indicator.human_name }
      if unit?
        default << :indicator_with_unit
        params[:unit] = unit.symbol
      end
      default << @indicator.human_name
      "procedure_handlers.#{name}".t(params.merge(default: default))
    end

    def backward_converters
      converters.select(&:backward?)
    end

    def forward_converters
      converters.select(&:forward?)
    end

    # Returns keys
    def depend_on?(variable_name, mode = nil)
      converters.each do |converter|
        return true if converter.depend_on?(variable_name, mode)
      end
      false
    end

    def forward_depend_on?(variable_name)
      depend_on?(variable_name, :forward)
    end

    def backward_depend_on?(variable_name)
      depend_on?(variable_name, :backward)
    end
  end
end
