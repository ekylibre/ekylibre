# coding: utf-8
module Procedo
  class Procedure
    # An Attribute defines an information to complete
    class Field
      attr_reader :name, :parameter

      delegate :procedure, to: :parameter
      delegate :name, to: :parameter, prefix: true
      delegate :name, to: :procedure, prefix: true

      delegate :parse!, :detect_parameter, :detect_environment_variable, :count_variables, to: :class

      class << self
        def code_trees(*snippets)
          options = snippets.extract_options!
          base_parse_options = {}
          base_parse_options[:root] = options[:root] if options[:root]
          snippets.each do |snippet|
            tree_name = snippet.to_s + '_tree'
            instance_var = '@' + tree_name
            attr_reader tree_name

            define_method "#{snippet}=" do |expr|
              parse_options = base_parse_options.merge(
                message: "Syntax error on #{self.class.name} (#{procedure_name}/#{parameter_name}##{@name}) #{snippet}."
              )
              instance_variable_set(instance_var, expr.blank? ? nil : parse!(expr.to_s, parse_options))
            end

            # Check if tree exist
            define_method "#{snippet}?" do
              instance_variable_get(instance_var).present?
            end

            # Check if given env variable is used
            define_method "#{snippet}_with_environment_variable?" do |*names|
              tree = instance_variable_get(instance_var)
              return false unless tree.present?
              names.each do |name|
                return true if detect_environment_variable(tree, name.to_s.upcase)
              end
            end
            alias_method "#{snippet}_env?", "#{snippet}_with_environment_variable?"

            # Check if given parameter is used
            define_method "#{snippet}_with_parameter?" do |parameter|
              tree = instance_variable_get(instance_var)
              return false unless tree.present?
              detect_parameter(tree, parameter)
            end

            # Check if given parameter is used
            define_method "#{snippet}_dependent_parameters" do
              tree = instance_variable_get(instance_var)
              return false unless tree.present?
              dependent_parameters(tree)
            end
          end
        end

        def parse!(code, options = {})
          return Procedo::Formula.parse(code.to_s, options)
        rescue Procedo::Formula::SyntaxError => e
          raise (options[:message] || "Syntax error in #{code.inspect}.") + ' ' + e.message + "\n" +
            code + "\n" + ('━' * e.failure_index) + '┛'
        end

        # Detects environment variables for the given name
        def detect_environment_variable(root, name)
          variable_name = name.to_s.upcase
          detect(root) do |node|
            node.is_a?(Procedo::Formula::Language::EnvironmentVariable) &&
              variable_name == node.text_value
          end
        end

        # Detects environment variables for the given name
        def detect_parameter(root, parameter)
          parameter_name = (parameter.is_a?(Procedo::Procedure::Parameter) ? parameter.name.to_s : parameter.to_s)
          detect(root) do |node|
            node.is_a?(Procedo::Formula::Language::Variable) &&
              parameter_name == node.text_value
          end
        end

        def dependent_parameters(root)
          parameters = []
          each(root) do |node|
            if node.is_a?(Procedo::Formula::Language::Variable)
              name = node.text_value.to_sym
              parameters << name unless parameters.include?(name)
            end
          end
          parameters
        end

        def detect(root, &block)
          return root if yield(root)
          if root.elements
            root.elements.each do |node|
              child = detect(node, &block)
              return child unless child.nil?
            end
          end
          nil
        end

        def each(root, &block)
          yield(root)
          if root.elements
            root.elements.each do |node|
              each(node, &block)
            end
          end
          root
        end

        # Count variables
        def count_variables(node, name)
          if (node.is_a?(Procedo::Formula::Language::Self) && name == :self) ||
             (node.is_a?(Procedo::Formula::Language::Variable) && name.to_s == node.text_value)
            return 1
          end
          return 0 unless node.elements
          node.elements.each_with_object(0) do |child, count|
            count += count_variables(child, name)
            count
          end
        end
      end

      def initialize(parameter, name, options = {})
        @parameter = parameter
        self.name = name
        @options = options
      end

      # Sets the name
      def name=(value)
        @name = value.to_sym
      end
    end
  end
end
