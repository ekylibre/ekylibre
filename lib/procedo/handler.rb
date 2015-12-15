require 'procedo/converter'

module Procedo
  # An Handler define a way to quantify an input/output
  class Handler
    attr_reader :name, :unit, :indicator, :converters, :parameter, :usability_tree, :widget

    delegate :procedure, to: :parameter
    delegate :datatype, to: :indicator

    def initialize(parameter, name, options = {})
      @parameter = parameter
      @name = name.to_sym
      @indicator = Nomen::Indicator[options[:indicator]]
      unless @indicator
        fail Procedo::Errors::InvalidHandler, "Handler of #{@parameter.name} must have a valid 'indicator' attribute. Got: #{options[:indicator].inspect}"
      end
      # Get and check measure unit
      if @indicator.datatype == :measure
        options[:unit] ||= @indicator.unit
        @unit = Nomen::Unit[options[:unit]]
        unless @unit
          fail Procedo::Errors::InvalidHandler, "Handler must have a valid 'unit' attribute. Got: #{options[:unit].inspect}"
        end
      end
      # Add condition
      unless options[:if].blank?
        begin
          @usability_tree = HandlerMethod.parse(options[:if].to_s, root: 'boolean_expression')
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{options.inspect}) #{parameter.procedure.name} has a syntax error on usability test (if): #{e.message}"
        end
      end
      # Define widget of handler (or parameter...)
      @widget = (options[:widget] || (@indicator.datatype == :geometry ? :map : :number)).to_sym
      # Initialize converters
      @converters = {}
      # Adds default converter
      converter_options = {}
      converter_options[:forward]  = (options[:forward].blank? ? 'value' : options[:forward])
      converter_options[:backward] = (options[:backward].blank? ? 'value' : options[:backward])
      add_converter(options[:to] || @indicator.name, converter_options)
    end

    # Adds a converter to the handler
    def add_converter(destination, options = {})
      converter = Procedo::Converter.new(self, destination, options)
      @converters[converter.destination] = converter
    end

    def unit?
      !@unit.blank?
    end

    def destinations
      converters.map(&:destination).uniq
    end

    def check_usability?
      !@usability_tree.nil?
    end

    # def destination_unique_name
    #   "#{@parameter.name}_#{destination}"
    # end

    # Returns the unique name of an handler inside a given procedure
    def unique_name
      "#{@parameter.name}-#{name}"
    end

    # Unique identifier for a given handler
    def uid
      "#{procedure.name}-#{unique_name}"
    end

    # Returns other handlers in the current parameter scope
    def others
      @parameter.handlers.select { |h| h != self }
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
    def depend_on?(parameter_name, mode = nil)
      converters.each do |converter|
        return true if converter.depend_on?(parameter_name, mode)
      end
      false
    end

    def forward_depend_on?(parameter_name)
      depend_on?(parameter_name, :forward)
    end

    def backward_depend_on?(parameter_name)
      depend_on?(parameter_name, :backward)
    end
  end
end
