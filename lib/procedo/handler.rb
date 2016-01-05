require 'procedo/converter'

module Procedo
  # An Handler define a way to quantify an input/output
  class Handler
    attr_reader :name, :unit, :indicator, :converters, :parameter, :usability_tree, :widget

    delegate :procedure, to: :parameter
    delegate :datatype, to: :indicator
    delegate :name, to: :parameter, prefix: true
    delegate :name, to: :procedure, prefix: true

    def initialize(parameter, name, options = {})
      @parameter = parameter
      self.name = name
      self.indicator_name = options[:indicator] || name
      self.unit_name = options[:unit] if self.measure?
      self.condition = options[:if] unless options[:if].blank?
      # Define widget of handler (or parameter...)
      @widget = (options[:widget] || (datatype == :geometry ? :map : :number)).to_sym
      # Initialize converters
      @converters = {}
      # Adds default converter
      converter_options = {}
      converter_options[:forward]  = (options[:forward].blank? ? 'value' : options[:forward])
      converter_options[:backward] = (options[:backward].blank? ? 'value' : options[:backward])
      add_converter(options[:to] || indicator.name, converter_options)
    end

    # Adds a converter to the handler
    def add_converter(destination, options = {})
      converter = Procedo::Converter.new(self, destination, options)
      @converters[converter.destination] = converter
    end

    # Sets the name
    def name=(value)
      @name = value.to_sym
    end

    # Sets the indicator
    def indicator=(value)
      @indicator = value
      unless @indicator.respond_to?(:nomenclature) && @indicator.nomenclature.name == :indicators
        fail Procedo::Errors::InvalidHandler, "Handler of #{@parameter.name} must have a valid 'indicator' attribute. Got: #{value.inspect}"
      end
      self.unit_name = indicator.unit if self.measure?
    end

    # Sets the indicator name
    def indicator_name=(value)
      self.indicator = Nomen::Indicator.find!(value)
    end

    # Sets the indicator name
    def unit_name=(value)
      fail 'Cant assign unit without indicator' unless indicator
      fail 'Cant assign unit with indicator which is not a measure' unless self.measure?
      unit = Nomen::Unit.find(value)
      unless unit
        fail Procedo::Errors::InvalidHandler, "Cannot find unit. Got: #{value.inspect}"
      end
      indicator_dimension = Nomen::Unit.find(indicator.unit).dimension
      unless unit.dimension == indicator_dimension
        fail "Dimension of unit (#{unit.dimension.inspect}) must be identical to indicator's (#{indicator_dimension.inspect}) in #{parameter_name}##{@name} of #{procedure_name}"
      end
      @unit = unit
    end

    def dimension_name
      @unit.dimension.to_sym
    end

    def measure?
      datatype == :measure
    end

    def unit?
      !@unit.blank?
    end

    def destinations
      converters.map(&:destination).uniq
    end

    def condition=(expr)
      @usability_tree = Formula::Language.parse(expr.to_s, root: 'boolean_expression')
    rescue SyntaxError => e
      raise SyntaxError, "A procedure handler (#{@name.inspect}) #{procedure.name} has a syntax error on usability test (if): #{e.message}"
    end

    def check_usability?
      !@usability_tree.nil?
    end

    def dimension_name
      @unit.dimension
    end

    def dimension
      Nomen::Dimension.find(@unit.dimension)
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
