module Procedo
  module Procedure
    module Codeable
      extend ActiveSupport::Concern

      delegate :parse!,
               :detect_parameter,
               :detect_environment_variable,
               :count_variables,
               to: :class

      module ClassMethods
        def code_trees(*snippets)
          options = snippets.extract_options!
          base_parse_options = {}
          base_parse_options[:root] = options[:root] if options[:root]
          snippets.each do |snippet|
            tree_name = snippet.to_s + "_tree"
            instance_var = "@" + tree_name
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
                detected = detect_environment_variable(tree, name.to_s.upcase)
                return true if detected
              end
            end
            alias_method "#{snippet}_env?",
                         "#{snippet}_with_environment_variable?"

            # Check if given parameter is used
            define_method "#{snippet}_with_parameter?" do |parameter|
              tree = instance_variable_get(instance_var)
              return false unless tree.present?
              detect_parameter(tree, parameter)
            end
          end
        end

        def parse!(code, options = {})
          return Procedo::Formula.parse(code.to_s, options)
        rescue Procedo::Formula::SyntaxError => e
          message = options[:message] || "Syntax error in #{code.inspect}."
          raise message + " " + e.message + "\n" +
                code + "\n" + ("━" * e.failure_index) + "┛"
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
          parameter_name = parameter
          if parameter_name.is_a? Procedo::Procedure::Parameter
            parameter_name = parameter_name.name
          end
          parameter_name = parameter_name.to_s
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
          node_is_self = node.is_a?(Procedo::Formula::Language::Self)
          node_is_variable = node.is_a?(Procedo::Formula::Language::Variable)
          if (node_is_self && name == :self) ||
             (node_is_variable && name.to_s == node.text_value)
            return 1
          end
          return 0 unless node.elements
          node.elements.reduce(0) do |count, child|
            count + count_variables(child, name)
          end
        end
      end
    end
  end
end
