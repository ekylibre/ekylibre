module Procedo
  module Engine
    class Interpreter
      def self.interpret(intervention, tree, env = {})
        new(intervention, env).interpret(tree)
      end

      def initialize(intervention, env = {})
        @intervention = intervention
        @self_value = env[:self]
        @value = env[:value]
      end

      def interpret(object)
        @value_calls_count = 0
        @variables = []
        run(object)
      end

      protected

      def run(object)
        if object.is_a?(Procedo::Formula::Language::Expression)
          run(object.expression)
        elsif object.is_a?(Procedo::Formula::Language::BooleanExpression)
          run(object.boolean_expression)
        elsif object.is_a?(Procedo::Formula::Language::Condition)
          run(object.test) ? run(object.if_true) : run(object.if_false)
        elsif object.is_a?(Procedo::Formula::Language::Conjunction)
          run(object.head) && run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::ExclusiveDisjunction)
          run(object.head) ^ run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Disjunction)
          run(object.head) || run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Multiplication)
          run(object.head) * run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Division)
          run(object.head) / run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Addition)
          run(object.head) + run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Substraction)
          run(object.head) - run(object.operand)
        elsif object.is_a?(Procedo::Formula::Language::Comparison)
          case object.operator.text_value
          when '>' then run(object.head) > run(object.operand)
          when '<' then run(object.head) < run(object.operand)
          when '>=' then run(object.head) >= run(object.operand)
          when '<=' then run(object.head) <= run(object.operand)
          when '==' then run(object.head) == run(object.operand)
          when '!=' then run(object.head) != run(object.operand)
          else
            fail 'Invalid operator: ' + object.operator.text_value
          end
        elsif object.is_a?(Procedo::Formula::Language::NegativeTest)
          !run(object.negated_test)
        elsif object.is_a?(Procedo::Formula::Language::FunctionCall)
          arguments = []
          args = object.args
          if args
            arguments << run(args.first_arg)
            if args.other_args
              object.args.other_args.elements.each do |other_arg|
                arguments << run(other_arg.argument)
              end
            end
          end
          Procedo::Engine::Functions.send(object.function_name.text_value.to_sym, *arguments)
        elsif object.is_a?(Procedo::Formula::Language::Symbol)
          object.text_value[1..-1].to_sym
        elsif object.is_a?(Procedo::Formula::Language::Value)
          @value_calls_count += 1
          @value
        elsif object.is_a?(Procedo::Formula::Language::Self)
          @self_value
        elsif object.is_a?(Procedo::Formula::Language::Variable)
          @variables << object.text_value.to_sym
          @intervention.parameters_of_name(object.text_value)
        elsif object.is_a?(Procedo::Formula::Language::Numeric)
          object.text_value.to_d
        elsif object.is_a?(Procedo::Formula::Language::ActorPresenceTest)
          run(object.actor).present?
        elsif object.is_a?(Procedo::Formula::Language::VariablePresenceTest)
          run(object.variable).any?
        elsif object.is_a?(Procedo::Formula::Language::IndicatorPresenceTest)
          indicator = Nomen::Indicator.find!(object.indicator.text_value)
          product = run(object.actor)
          product.has_indicator?(indicator.name) && (indicator.datatype == :measure ? product.get(indicator.name).to_f != 0 : product.get(indicator.name).present?)
        elsif object.is_a?(Procedo::Formula::Language::IndividualIndicatorPresenceTest)
          indicator = Nomen::Indicator.find!(object.indicator.text_value)
          product = run(object.actor)
          product.frozen_indicators.include?(indicator.name) && (indicator.datatype == :measure ? product.get(indicator.name).to_f != 0 : product.get(indicator.name).present?)
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
          prodi = run(object.actor)
          if object.is_a?(Procedo::Formula::Language::IndividualReading)
            prodi = prodi.variant
          end
          prodi.get(indicator.name.to_sym).to_f(unit ? unit.name : nil)
        elsif object.nil?
          null
        else
          fail 'Dont known how to manage: ' + object.class.name
        end
      end
    end
  end
end
