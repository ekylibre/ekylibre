module Procedo

  module HandlerMethod
    class Base < Treetop::Runtime::SyntaxNode
      def to_hash
        self
      end
    end

    class Expression < Base
      def to_hash
        self.elements[0].to_hash
      end
    end

    class Operation < Base
      def to_hash
        {self.class.name.underscore.split('/').last.to_sym => {head: self.elements[0].to_hash, operand: self.elements[1].to_hash}}
      end
    end

    class Multiplication < Operation
    end

    class Division < Operation
    end

    class Addition < Operation
    end

    class Substraction < Operation
    end

    class IndividualReading < Base
      def to_hash
        {individual_reading: [elements[0].to_hash, elements[1].to_hash]}
      end      
    end

    class WholeReading < Base
      def to_hash
        {whole_reading: [elements[0].to_hash, elements[1].to_hash]}
      end      
    end

    class Variable < Base
      def to_hash
        self.text_value.to_sym
      end      
    end

    class Indicator < Base
      def to_hash
        Nomen::Indicators[self.text_value]
      end
    end

    class Self < Base
      def to_hash
        :self
      end
    end

    class Number < Base
      def to_hash
        self.text_value.to_d
      end
    end

    class Value < Base
      def to_hash
        :value
      end
    end

    class << self

      def parse(text)
        @@parser ||= ::Procedo::HandlerMethodParser.new
        if tree = @@parser.parse(text.to_s)
          clean_tree(tree)
          tree = tree.to_hash
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

    attr_reader :unit, :indicator, :destination, :method_tree

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
      @method_tree = HandlerMethod.parse(element[:method].to_s)

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
