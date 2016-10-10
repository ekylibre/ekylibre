module Procedo
  module Engine
    class Interpreter
      def self.interpret(intervention, tree, env = {})
        new(intervention, env).interpret(tree)
      end

      def initialize(intervention, env = {})
        @intervention = intervention
        @env = env.each_with_object({}) do |(k, v), h|
          h[k.to_s.upcase] = v
          h
        end
        # puts @env.map { |k, v| k.to_s.red + ': ' + v.class.name.yellow }.join(', ')
      end

      def interpret(node)
        @variables = []
        run(node)
      end

      protected

      def run(node)
        if node.is_a?(Procedo::Formula::Language::Expression)
          run(node.expression)
        elsif node.is_a?(Procedo::Formula::Language::BooleanExpression)
          run(node.boolean_expression)
        elsif node.is_a?(Procedo::Formula::Language::Condition)
          run(node.test) ? run(node.if_true) : run(node.if_false)
        elsif node.is_a?(Procedo::Formula::Language::Conjunction)
          run(node.head) && run(node.operand)
        elsif node.is_a?(Procedo::Formula::Language::ExclusiveDisjunction)
          run(node.head) ^ run(node.operand)
        elsif node.is_a?(Procedo::Formula::Language::Disjunction)
          run(node.head) || run(node.operand)
        elsif node.is_a?(Procedo::Formula::Language::Multiplication)
          run(node.head) * run(node.operand)
        elsif node.is_a?(Procedo::Formula::Language::Division)
          raise "Cannot divide by zero: #{node.head.text_value} / #{node.operand.text_value} (#{run(node.head)} / #{run(node.operand)})" if run(node.operand).zero?
          result = run(node.head) / run(node.operand)
          result
        elsif node.is_a?(Procedo::Formula::Language::Addition)
          run(node.head) + run(node.operand)
        elsif node.is_a?(Procedo::Formula::Language::Substraction)
          run(node.head) - run(node.operand)
        elsif node.is_a?(Procedo::Formula::Language::Comparison)
          case node.operator.text_value
          when '>' then run(node.head) > run(node.operand)
          when '<' then run(node.head) < run(node.operand)
          when '>=' then run(node.head) >= run(node.operand)
          when '<=' then run(node.head) <= run(node.operand)
          when '==' then run(node.head) == run(node.operand)
          when '!=' then run(node.head) != run(node.operand)
          else
            raise 'Invalid operator: ' + node.operator.text_value
          end
        elsif node.is_a?(Procedo::Formula::Language::NegativeTest)
          !run(node.negated_test)
        elsif node.is_a?(Procedo::Formula::Language::FunctionCall)
          arguments = []
          args = node.args
          if args
            arguments << run(args.first_arg)
            if args.other_args
              node.args.other_args.elements.each do |other_arg|
                arguments << run(other_arg.argument)
              end
            end
          end
          Procedo::Engine::Functions.send(node.function_name.text_value.to_sym, *arguments)
        elsif node.is_a?(Procedo::Formula::Language::Symbol)
          node.text_value[1..-1].to_sym
        elsif node.is_a?(Procedo::Formula::Language::EnvironmentVariable)
          @env[node.text_value]
        elsif node.is_a?(Procedo::Formula::Language::Variable)
          @variables << node.text_value.to_sym
          @intervention.parameter_set(node.text_value)
        elsif node.is_a?(Procedo::Formula::Language::Numeric)
          node.text_value.to_d
        elsif node.is_a?(Procedo::Formula::Language::ActorPresenceTest)
          # puts "PRESENCE: #{run(node.object)}".blue
          run(node.object).present?
        elsif node.is_a?(Procedo::Formula::Language::VariablePresenceTest)
          run(node.variable).any?
        elsif node.is_a?(Procedo::Formula::Language::IndicatorPresenceTest)
          indicator = Nomen::Indicator.find!(node.indicator.text_value)
          product = run(node.object)
          unless product.is_a?(Product) || product.is_a?(ProductNatureVariant)
            Rails.logger.warn 'Invalid product. Got: ' + product.inspect
            return false
          end

          !!(product.has_indicator?(indicator.name.to_sym) &&
            (indicator.datatype == :measure ? product.get(indicator.name).to_f.nonzero? : product.get(indicator.name).present?))
        elsif node.is_a?(Procedo::Formula::Language::IndividualIndicatorPresenceTest)
          indicator = Nomen::Indicator.find!(node.indicator.text_value)
          product = run(node.object)
          unless product.is_a?(Product)
            Rails.logger.warn 'Invalid product. Got: ' + product.inspect
            return false
          end
          variant = product.variant

          !!(variant.has_frozen_indicator?(indicator.name.to_sym) &&
            (indicator.datatype == :measure ? variant.get(indicator.name.to_sym).to_f.nonzero? : variant.get(indicator.name.to_sym).present?))
        elsif node.is_a?(Procedo::Formula::Language::Reading)
          unit = nil
          if node.options && node.options.respond_to?(:unit)
            unless unit = Nomen::Unit[node.options.unit.text_value]
              raise "Valid unit expected in #{node.inspect}"
            end
          end
          unless indicator = Nomen::Indicator[node.indicator.text_value]
            raise 'Invalid indicator: ' + node.indicator.text_value.inspect
          end
          product = run(node.object)
          # TODO: Manage when no product...
          unless product.is_a?(Product) || product.is_a?(ProductNatureVariant)
            Rails.logger.warn 'Invalid product. Got: ' + product.inspect + ' ' + node.text_value
            # raise 'Invalid product: Got: ' + product.inspect + ' ' + node.text_value
          end
          if node.is_a?(Procedo::Formula::Language::IndividualReading)
            product = product.variant
          end

          value = product.get(indicator.name.to_sym, @env['READ_AT'])
          value = value.to_f(unit.name) if unit
          value
        elsif node.nil?
          null
        else
          raise 'Dont known how to manage node: ' + node.class.name
        end
      end
    end
  end
end
