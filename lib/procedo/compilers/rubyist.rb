module Procedo
  module Compilers
    class Rubyist
      attr_reader :variables, :compiled, :value_calls_count
      attr_accessor :value, :self_value

      def initialize(options = {})
        @self_value = options[:self] || 'self'
        @value = options[:value] || 'value'
      end

      def compile(object)
        @variables = []
        @value_calls_count = 0
        @compiled = rewrite(object)
        compiled
      end

      protected

      def rewrite(object)
        if object.is_a?(Procedo::Formula::Language::Expression)
          '(' + rewrite(object.expression) + ')'
        elsif object.is_a?(Procedo::Formula::Language::BooleanExpression)
          '(' + rewrite(object.boolean_expression) + ')'
        elsif object.is_a?(Procedo::Formula::Language::Condition)
          rewrite(object.test) + ' ? ' + rewrite(object.if_true) + ' : ' + rewrite(object.if_false)
        elsif object.is_a?(Procedo::Formula::Language::Conjunction)
          rewrite(object.head) + ' and ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::ExclusiveDisjunction)
          rewrite(object.head) + ' xor ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Disjunction)
          rewrite(object.head) + ' or ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Multiplication)
          rewrite(object.head) + ' * ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Division)
          rewrite(object.head) + ' / ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Addition)
          rewrite(object.head) + ' + ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Substraction)
          rewrite(object.head) + ' - ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Comparison)
          rewrite(object.head) + ' ' + object.operator.text_value + ' ' + rewrite(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::NegativeTest)
          'not ' + rewrite(object.negated_test)
        elsif object.is_a?(Procedo::Formula::Language::FunctionCall)
          arguments = ''
          if args = object.args
            arguments << rewrite(args.first_arg)
            for other_arg in args.other_args.elements
              arguments << ', ' + rewrite(other_arg.argument)
            end if args.other_args
          end
          "::Procedo::FormulaFunctions.#{object.function_name.text_value}(" + arguments + ')'
        elsif object.is_a?(Procedo::Formula::Language::Value)
          @value_calls_count += 1
          @value.to_s
        elsif object.is_a?(Procedo::Formula::Language::Self)
          @self_value.to_s
        elsif object.is_a?(Procedo::Formula::Language::Variable)
          @variables << object.text_value.to_sym
          "procedure.#{object.text_value}"
        elsif object.is_a?(Procedo::Formula::Language::Numeric)
          object.text_value.to_s
        elsif object.is_a?(Procedo::Formula::Language::Access)
          rewrite(object.actor) + '.' + object.accessor.text_value.tr('-', '_')
        elsif object.is_a?(Procedo::Formula::Language::ActorPresenceTest)
          rewrite(object.actor) + '.present?'
        elsif object.is_a?(Procedo::Formula::Language::IndicatorPresenceTest)
          rewrite(object.actor) + '.has_indicator?(:' + object.indicator.text_value + ')'
        elsif object.is_a?(Procedo::Formula::Language::Reading)
          unit = nil
          if object.options && object.options.respond_to?(:unit)
            unless unit = Nomen::Unit[object.options.unit.text_value]
              fail "Valid unit expected in #{object.inspect}"
            end
          end
          unless indicator = Nomen::Indicator[object.indicator.text_value]
            fail "Invalid indicator: #{object.indicator.text_value.inspect}"
          end
          rewrite(object.actor) +
            '.get(:' + indicator.name.to_s +
            (object.is_a?(Procedo::Formula::Language::IndividualReading) ? ', individual: true' : '') +
            ')' +
            (unit ? ".to_f(:#{unit.name})" : '')
        elsif object.nil?
          'null'
        else
          '(' + object.class.name + ')'
        end
      end
    end
  end
end
