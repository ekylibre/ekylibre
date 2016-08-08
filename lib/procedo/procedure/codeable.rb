# coding: utf-8
module Procedo
  class Procedure
    module Codeable
      extend ActiveSupport::Concern

      delegate :parse!,
               :detect_parameter,
               :detect_environment_variable,
               :count_variables,
               to: :class

      module ClassMethods
        # Parse and build syntax trees for given object variables
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
                message: "Syntax error on #{self.class.name} #{snippet}."
              )
              inst_value = expr.blank? ? nil : parse!(expr.to_s, parse_options)
              instance_variable_set(instance_var, inst_value)
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
                detected = self.class.detect_environment_variable(tree, name.to_s.upcase)
                return true if detected
              end
            end
            alias_method "#{snippet}_env?",
                         "#{snippet}_with_environment_variable?"

            # Check if given parameter is used
            define_method "#{snippet}_with_parameter?" do |parameter|
              tree = instance_variable_get(instance_var)
              return false unless tree.present?
              self.class.detect_parameter(tree, parameter)
            end

            # Returns list of parameter used in code
            define_method "#{snippet}_parameters" do
              tree = instance_variable_get(instance_var)
              return [] unless tree.present?
              self.class.select_nodes(tree) do |node|
                node.is_a?(Procedo::Formula::Language::Variable)
              end.map(&:text_value)
            end
          end
        end

        def parse!(code, options = {})
          return Procedo::Formula.parse(code.to_s, options)
        rescue Procedo::Formula::SyntaxError => e
          message = options[:message] || "Syntax error in #{code.inspect}."
          raise message + ' ' + e.message + "\n" +
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
          parameter_name = if parameter_name.is_a? Procedo::Procedure::Parameter
                             parameter.name
                           else
                             parameter.to_s
                           end
          detect(root) do |node|
            node.is_a?(Procedo::Formula::Language::Variable) &&
              parameter_name == node.text_value
          end
        end

        def detect(root, &block)
          return root if yield(root)
          if root.elements
            root.elements.each do |node|
              child = detect(node, &block)
              return child if child
            end
          end
          nil
        end

        # Browse all nodes and select which match block
        def select_nodes(root, &block)
          list = []
          list << root if yield(root)
          if root.elements
            root.elements.each do |node|
              list += select_nodes(node, &block)
            end
          end
          list
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
          node_is_self = node.is_a?(Procedo::Formula::Language::Self)
          node_is_variable = node.is_a?(Procedo::Formula::Language::Variable)
          if (node_is_self && name == :self) ||
             (node_is_variable && name.to_s == node.text_value)
            return 1
          end
          return 0 unless node.elements
          node.elements.inject(0) do |count, child|
            count + count_variables(child, name)
          end
        end
      end
    end
  end
end
