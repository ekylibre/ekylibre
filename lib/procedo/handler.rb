# coding: utf-8
# require 'procedo/converter'

module Procedo
  module Formula
    class SyntaxError < StandardError
      attr_reader :parser
      delegate :failure_index, :failure_column, :failure_line, to: :parser
      def initialize(parser)
        @parser = parser
        super(@parser.failure_reason)
      end
    end

    class Parser < Treetop::Runtime::CompiledParser
      include Procedo::Formula::Language
    end

    module Language
      class Base < Treetop::Runtime::SyntaxNode; end
      class Expression < Base; end
      class Condition < Base; end
      class Operation < Base; end # Abstract
      class Multiplication < Operation; end
      class Division < Operation; end
      class Addition < Operation; end
      class Substraction < Operation; end
      class BooleanExpression < Base; end
      class BooleanOperation < Base; end
      class Conjunction < BooleanOperation; end
      class Disjunction < BooleanOperation; end
      class ExclusiveDisjunction < BooleanOperation; end
      class Test < Base; end # Abstract
      class Comparison < Test; end # Abstract
      class StrictSuperiorityComparison < Comparison; end
      class StrictInferiortyComparison < Comparison; end
      class SuperiorityComparison < Comparison; end
      class InferiorityComparison < Comparison; end
      class EqualityComparison < Comparison; end
      class DifferenceComparison < Comparison; end
      class IndicatorPresenceTest < Test; end
      class IndividualIndicatorPresenceTest < Test; end
      class VariablePresenceTest < Test; end
      class NegativeTest < Test; end
      class Reading < Base; end # Abstract
      class IndividualReading < Reading; end
      class WholeReading < Reading; end
      class FunctionCall < Base; end
      class FunctionName < Base; end
      class OtherArgument < Base; end
      class Variable < Base; end
      class Indicator < Base; end
      class Unit < Base; end
      class Self < Base; end
      class Value < Base; end
      class Numeric < Base; end
      class Symbol < Base; end

      class << self
        def parse(text, options = {})
          @@parser ||= ::Procedo::Formula::Parser.new
          unless tree = @@parser.parse(text.to_s, options)
            fail Formula::SyntaxError, @@parser
          end
          tree
        end

        # def clean_tree(root)
        #   return if root.elements.nil?
        #   root.elements.delete_if{ |node| node.class.name == "Treetop::Runtime::SyntaxNode" }
        #   root.elements.each{ |node| clean_tree(node) }
        # end
      end
    end
  end

  # An Handler define a way to quantify an input/output
  class Handler
    attr_reader :name, :unit, :indicator, :converters, :parameter, :condition_tree, :backward_tree, :forward_tree, :widget

    delegate :procedure, to: :parameter
    delegate :datatype, to: :indicator
    delegate :name, to: :parameter, prefix: true
    delegate :name, to: :procedure, prefix: true
    delegate :parse!, :count_variables, to: :class

    class << self
      def parse!(code, options = {})
        return Formula::Language.parse(code.to_s, options)
      rescue Formula::SyntaxError => e
        raise (options[:message] || "Syntax error in #{code.inspect}.") + ' ' + e.message + "\n" +
          code + "\n" + ('━' * e.failure_index) + '┛'
      end

      def count_variables(node, name)
        if (node.is_a?(Procedo::Formula::Language::Self) && name == :self) ||
           (node.is_a?(Procedo::Formula::Language::Variable) && name.to_s == node.text_value)
          return 1
        end
        return 0 unless node.elements
        node.elements.inject(0) do |count, child|
          count += count_variables(child, name)
          count
        end
      end
    end

    def initialize(parameter, name, options = {})
      @parameter = parameter
      @trees = {}.with_indifferent_access
      self.name = name
      self.indicator_name = options[:indicator] || name
      self.unit_name = options[:unit] if self.measure?
      self.condition = options[:if] unless options[:if].blank?
      self.forward = options[:forward] unless options[:forward].blank?
      self.backward = options[:backward] unless options[:backward].blank?
      # Define widget of handler (or parameter...)
      @widget = (options[:widget] || (datatype == :geometry ? :map : :number)).to_sym
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

    def dimension_name
      @unit.dimension
    end

    def dimension
      Nomen::Dimension.find(@unit.dimension)
    end

    def condition=(expr)
      @condition_tree = parse!(expr.to_s, root: 'boolean_expression', message: "Syntax error on handler (#{procedure.name}/#{@parameter.name}##{@name}) conditional test (if).")
    end

    def forward=(expr)
      @forward_tree = parse!(expr, message: "Syntax error on handler (#{procedure.name}/#{@parameter.name}##{@name}) forward formula.")
    end

    def backward=(expr)
      @backward_tree = parse!(expr, message: "Syntax error on handler (#{procedure.name}/#{@parameter.name}##{@name}) backward formula.")
    end

    def condition?
      @condition_tree.present?
    end

    def forward?
      @forward_tree.present?
    end

    def backward?
      @backward_tree.present?
    end

    # # Returns the unique name of an handler inside a given procedure
    # def unique_name
    #   "#{@parameter.name}-#{name}"
    # end

    # # Unique identifier for a given handler
    # def uid
    #   "#{procedure.name}-#{unique_name}"
    # end

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
    def depend_on?(parameter_name, modes = nil)
      modes ||= [:forward, :backward, :condition]
      modes = [modes] unless modes.is_a?(Array)
      modes.each do |mode|
        if tree?(mode)
          return true if count_variables(tree(mode), parameter_name) > 0
        end
      end
      false
    end
  end
end
