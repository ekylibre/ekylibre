require 'procedo/formula/language'

module Procedo
  module Formula
    class LanguageParser < Treetop::Runtime::CompiledParser
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
      class ActorPresenceTest < Test; end
      class NegativeTest < Test; end
      class Access < Base; end
      class Reading < Base; end # Abstract
      class IndividualReading < Reading; end
      class WholeReading < Reading; end
      class FunctionCall < Base; end
      class FunctionName < Base; end
      class OtherArgument < Base; end
      class Variable < Base; end
      class Accessor < Base; end
      class Indicator < Base; end
      class Unit < Base; end
      class Self < Base; end
      class Value < Base; end
      class Numeric < Base; end
      class Symbol < Base; end

      class << self
        def parse(text, options = {})
          @@parser ||= ::Procedo::Formula::LanguageParser.new
          unless tree = @@parser.parse(text.to_s, options)
            fail SyntaxError, @@parser.failure_reason
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

  class Converter
    @@whole_indicators = Nomen::Indicator.where(related_to: :whole).collect { |i| i.name.to_sym }
    cattr_reader :whole_indicators

    attr_reader :destination, :backward_tree, :forward_tree, :handler

    class << self
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

    def initialize(handler, _destination, options = {})
      @handler = handler
      # @destination = destination.to_sym
      # unless @@whole_indicators.include?(@destination)
      #   fail Procedo::Errors::InvalidHandler, "Handler must have a valid destination (#{@@whole_indicators.to_sentence} expected, got #{@destination})"
      # end
      if options[:forward]
        begin
          @forward_tree = Formula::Language.parse(options[:forward].to_s)
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{options.inspect}) #{handler.procedure.name} has a syntax error on forward formula: #{e.message}"
        end
      end
      if options[:backward]
        begin
          @backward_tree = Formula::Language.parse(options[:backward].to_s)
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{options.inspect}) #{handler.procedure.name} has a syntax error on backward formula: #{e.message}"
        end
      end
    end

    def forward?
      @forward_tree.present?
    end

    def backward?
      @backward_tree.present?
    end

    # Parameter
    def parameter
      @handler.parameter
    end

    # Procedure
    def procedure
      @handler.procedure
    end

    # Returns keys
    def depend_on?(parameter_name, mode = nil)
      count = 0
      if forward? && (mode.nil? || mode == :forward)
        count += self.class.count_variables(@forward_tree, parameter_name)
      end
      if backward? && (mode.nil? || mode == :backward)
        count += self.class.count_variables(@backward_tree, parameter_name)
      end
      !count.zero?
    end
  end
end
