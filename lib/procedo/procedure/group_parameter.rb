# require 'procedo/procedure/parameter'

module Procedo
  class Procedure
    # Parameter group is a a group of parameter like a directory in a FS.
    class GroupParameter < Procedo::Procedure::Parameter
      def initialize(procedure, name, options = {})
        super(procedure, name, options)
        @parameters = {}.with_indifferent_access
      end

      # Returns all parameters of the group
      # If +recursively+ is true, it will retrieve all parameters of sub-groups too.
      def parameters(recursively = false)
        recursively ? all_parameters : @parameters.values
      end

      def group_parameters(recursively = false)
        parameters(recursively).select { |i| i.is_a?(Procedo::Procedure::GroupParameter) }
      end

      def product_parameters(recursively = false)
        parameters(recursively).select { |i| i.is_a?(Procedo::Procedure::ProductParameter) }
      end

      # Returns an parameter with its name
      def fetch(name)
        @parameters[name]
      end
      alias [] fetch

      # Returns parameter with its name. Returns nil if not found
      def find(name, _type = nil)
        browse_all do |i|
          return i if i.name.to_s == name.to_s
        end
        nil
      end

      # Returns parameter with its name. Raise exception if parameter not found
      def find!(name)
        parameter = find(name)
        raise "Cannot find parameter: #{name.inspect}" unless parameter
        parameter
      end

      # Returns position of a parameter in the group relatively to the current
      # group parameter.
      # First element has position 1.
      def position_of(parameter)
        index = 1
        browse_all do |i|
          return index if i == parameter
          index += 1
        end
        nil
      end

      # Browse parameters in their order
      def each_parameter(recursively = false, &block)
        recursively ? browse_all(&block) : @parameters.values.each(&block)
      end

      # Browse product_parameters in their order
      def each_product_parameter(recursively = false, &_block)
        each_parameter(recursively) do |parameter|
          yield(parameter) if parameter.is_a?(Procedo::Procedure::ProductParameter)
        end
      end

      # Browse group_parameters in their order
      def each_group_parameter(recursively = false, &_block)
        each_parameter(recursively) do |parameter|
          yield(parameter) if parameter.is_a?(Procedo::Procedure::GroupParameter)
        end
      end

      def add_product_parameter(name, type, options = {})
        options[:group] = self
        parameter = Procedo::Procedure::ProductParameter.new(@procedure, name, type, options)
        @parameters[parameter.name] = parameter
      end

      def add_group_parameter(name, options = {})
        options[:group] = self
        parameter = Procedo::Procedure::GroupParameter.new(@procedure, name, options)
        @parameters[parameter.name] = parameter
      end

      protected

      # Retrieve all (nested or not) Parameter objects in the group in the order
      # defined by default.
      def all_parameters
        list = []
        browse_all do |parameter|
          list << parameter
        end
        list
      end

      def browse_all(&block)
        @parameters.each do |_k, parameter|
          yield parameter
          parameter.browse_all(&block) if parameter.is_a?(Procedo::Procedure::GroupParameter)
        end
      end
    end
  end
end
