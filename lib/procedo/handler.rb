module Procedo

  module HandlerMethod

    class Base < Treetop::Runtime::SyntaxNode
    end

    class Expression < Base
    end

    class Operation < Base
    end

    class Multiplication < Operation
    end

    class Division < Operation
    end

    class Addition < Operation
    end

    class Substraction < Operation
    end

    class Reading < Base
    end

    class MeasureReading < Reading
    end

    class IndividualReading < Reading
    end

    class WholeReading < Reading
    end

    class IndividualMeasureReading < MeasureReading
    end

    class WholeMeasureReading < MeasureReading
    end

    class Variable < Base
    end

    class Indicator < Base
    end

    class Unit < Base
    end

    class Self < Base
    end

    class Numeric < Base
    end

    class Value < Base
    end

    class << self

      def parse(text)
        @@parser ||= ::Procedo::HandlerMethodParser.new
        unless tree = @@parser.parse(text.to_s)
          raise SyntaxError, "Parse error at offset #{@@parser.index} in #{text.to_s.inspect}"
        end
        return tree
      end

      def clean_tree(root)
        return if root.elements.nil?
        root.elements.delete_if{ |node| node.class.name == "Treetop::Runtime::SyntaxNode" }
        root.elements.each{ |node| clean_tree(node) }
      end

    end

  end

  class Handler

    @@whole_indicators = Nomen::Indicators.where(related_to: :whole).collect{|i| i.name.to_sym }

    attr_reader :unit, :indicator, :destination, :forward_tree, :backward_tree

    def initialize(variable, element = nil)
      @variable = variable
      # Extract attributes from XML element
      unless element.is_a?(Hash)
        element = %w(forward backward indicator unit to datatype).inject({}) do |hash, attr|
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
      element[:forward]  = "value" if element[:forward].blank?
      element[:backward] = "value" if element[:backward].blank?
      @destination = element[:to]
      # Load values
      begin
        @forward_tree = HandlerMethod.parse(element[:forward].to_s)
      rescue SyntaxError => e
        raise SyntaxError, "A procedure handler (#{element.inspect}) #{variable.procedure.name} has a syntax error on forward formula: #{e.message}"
      end
      begin
        @backward_tree = HandlerMethod.parse(element[:backward].to_s)
      rescue SyntaxError => e
        raise SyntaxError, "A procedure handler (#{element.inspect}) #{variable.procedure.name} has a syntax error on backward formula: #{e.message}"
      end

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

    def datatype
      @indicator.datatype
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
