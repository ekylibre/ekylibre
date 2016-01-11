# coding: utf-8
# require 'procedo/formula'
module Procedo
  class Procedure
    # An Handler define a way to quantify a population
    class Handler < Procedo::Procedure::Field
      TYPES = [:indicator, :population]

      code_trees :condition, root: 'boolean_expression'
      code_trees :forward, :backward

      attr_reader :unit, :indicator, :parameter, :widget

      def initialize(parameter, name, options = {})
        super(parameter, name, options)
        @trees = {}.with_indifferent_access
        options[:type] ||= :population if @name == :population
        @type = options[:type] || :indicator
        fail 'Invalid type: ' + @type.inspect unless TYPES.include?(@type)
        if indicator?
          self.indicator_name = options[:indicator] || @name
          self.unit_name = options[:unit] if self.measure?
        elsif population?
          options[:forward] = 'VALUE'
          options[:backward] = 'POPULATION'
          # options[:if] ||= 'PRODUCT?'
        end
        self.condition = options[:if]
        self.forward = options[:forward]
        self.backward = options[:backward]
        # Define widget of handler (or parameter...)
        @widget = (options[:widget] || (datatype == :geometry ? :map : :number)).to_sym
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

      def indicator?
        @type == :indicator
      end

      def population?
        @type == :population
      end

      def datatype
        population? ? :decimal : indicator.datatype
      end

      def measure?
        datatype == :measure
      end

      def unit?
        !@unit.blank?
      end

      def dimension_name
        @unit.dimension
      end

      def dimension
        Nomen::Dimension.find(@unit.dimension)
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
        name.t(params.merge(default: default, scope: 'procedure_handlers'))
      end

      def tree(name)
        if name == :backward
          @backward_tree
        elsif name == :forward
          @forward_tree
        elsif name == :condition
          @condition_tree
        else
          fail 'Unknown tree: ' + name.inspect
        end
      end

      def tree?(name)
        tree(name).present?
      end

      # Returns keys
      def depend_on?(parameter_name)
        condition_with_parameter?(parameter_name) ||
          backward_with_parameter?(parameter_name) ||
          forward_with_parameter?(parameter_name)
      end

      def dependent_parameters
        parameters = handler.condition_dependent_parameters
        parameters += handler.backward_dependent_parameters
        parameters += handler.forward_dependent_parameters
        parameters.uniq
      end
    end
  end
end
