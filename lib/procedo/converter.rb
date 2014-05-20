module Procedo

  module HandlerMethod

    class Base < Treetop::Runtime::SyntaxNode; end
    class Expression                  < Base              ; end
    class Condition                   < Base              ; end
    class Operation                   < Base              ; end  # Abstract
    class Multiplication              < Operation         ; end
    class Division                    < Operation         ; end
    class Addition                    < Operation         ; end
    class Substraction                < Operation         ; end
    class BooleanExpression           < Base              ; end
    class BooleanOperation            < Base              ; end
    class Conjunction                 < BooleanOperation  ; end
    class Disjunction                 < BooleanOperation  ; end
    class ExclusiveDisjunction        < BooleanOperation  ; end
    class Test                        < Base              ; end # Abstract
    class Comparison                  < Test              ; end # Abstract
    class StrictSuperiorityComparison < Comparison        ; end
    class StrictInferiortyComparison  < Comparison        ; end
    class SuperiorityComparison       < Comparison        ; end
    class InferiorityComparison       < Comparison        ; end
    class EqualityComparison          < Comparison        ; end
    class DifferenceComparison        < Comparison        ; end
    class IndicatorPresenceTest       < Test              ; end
    class ActorPresenceTest           < Test              ; end
    class NegativeTest                < Test              ; end
    class Access                      < Base              ; end
    class Reading                     < Base              ; end # Abstract
    class IndividualReading           < Reading           ; end
    class WholeReading                < Reading           ; end
    class FunctionCall                < Base              ; end
    class FunctionName                < Base              ; end
    class OtherArgument               < Base              ; end
    class Variable                    < Base              ; end
    class Accessor                    < Base              ; end
    class Indicator                   < Base              ; end
    class Unit                        < Base              ; end
    class Self                        < Base              ; end
    class Value                       < Base              ; end
    class Numeric                     < Base              ; end

    class << self

      def parse(text, options = {})
        @@parser ||= ::Procedo::HandlerMethodParser.new
        unless tree = @@parser.parse(text.to_s, options)
          raise SyntaxError, "Parse error at offset #{@@parser.index} in #{text.to_s.inspect}"
        end
        return tree
      end

      # def clean_tree(root)
      #   return if root.elements.nil?
      #   root.elements.delete_if{ |node| node.class.name == "Treetop::Runtime::SyntaxNode" }
      #   root.elements.each{ |node| clean_tree(node) }
      # end

    end

  end


  class Converter

    @@whole_indicators = Nomen::Indicators.where(related_to: :whole).collect{|i| i.name.to_sym }
    cattr_reader :whole_indicators

    attr_reader :destination, :backward_tree, :forward_tree, :handler

    class << self

      def count_variables(node, name)
        if (node.is_a?(Procedo::HandlerMethod::Self) and name == :self) or 
            (node.is_a?(Procedo::HandlerMethod::Variable) and name.to_s == node.text_value)
          return 1
        end
        return 0 unless node.elements
        return node.elements.inject(0) do |count, child|
          count += count_variables(child, name)
          count
        end
      end

    end
    

    def initialize(handler, element = nil)
      @handler = handler
      # Extract attributes from XML element
      unless element.is_a?(Hash)
        element = %w(forward backward to).inject({}) do |hash, attr|
          if element.has_attribute?(attr)
            hash[attr.to_sym] = element.attr(attr)
          end
          hash
        end
      end

      @destination = (element[:to] || @handler.indicator.name).to_sym
      unless @@whole_indicators.include?(@destination)
        raise Procedo::Errors::InvalidHandler, "Handler must have a valid destination (#{@@whole_indicators.to_sentence} expected, got #{@destination})"
      end

      if element[:forward]
        begin
          @forward_tree = HandlerMethod.parse(element[:forward].to_s)
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{element.inspect}) #{handler.procedure.name} has a syntax error on forward formula: #{e.message}"
        end
      end

      if element[:backward]
        begin
          @backward_tree = HandlerMethod.parse(element[:backward].to_s)
        rescue SyntaxError => e
          raise SyntaxError, "A procedure handler (#{element.inspect}) #{handler.procedure.name} has a syntax error on backward formula: #{e.message}"
        end
      end
    end

    def forward?
      @forward_tree.present?
    end

    def backward?
      @backward_tree.present?
    end

    # Variable
    def variable
      @handler.variable
    end

    # Procedure
    def procedure
      @handler.procedure
    end

    # Returns keys
    def depend_on?(variable_name, mode = nil)
      count = 0
      if forward? and (mode.nil? or mode == :forward)
        count += self.class.count_variables(@forward_tree, variable_name)
      end
      if backward? and (mode.nil? or mode == :backward)
        count += self.class.count_variables(@backward_tree, variable_name)
      end
      return !count.zero?
    end

  end

end
