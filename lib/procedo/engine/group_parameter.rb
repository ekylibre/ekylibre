require 'procedo/engine/parameter'

module Procedo
  module Engine
    class GroupParameter < Procedo::Engine::Parameter
      CHILDREN_PARAM_NAMES = [:doers_attributes, :inputs_attributes,
                              :outputs_attributes, :targets_attributes,
                              :tools_attributes, :group_parameters_attributes]

      def initialize(intervention, id, attributes = {})
        super(intervention, id, attributes)
        @members = {}.with_indifferent_access
      end

      def parse_params(params)
        CHILDREN_PARAM_NAMES.each do |param_name|
          next unless params[param_name]
          params[param_name].each do |id, attributes|
            puts "Add #{param_name}: #{id} (#{attributes.inspect})".magenta
            add(param_name, id, attributes)
          end
        end
      end

      def to_hash
        hash = { reference_name: @reference.name }
        each_member do |parameter|
          param_name = parameter.param_name
          hash[param_name] ||= {}
          hash[param_name][parameter.id.to_s] = parameter.to_hash
        end
        hash
      end

      def each_member(&block)
        @members.each do |_, m|
          m.each(&block)
        end
      end

      def add(param_name, id, attributes = {})
        if param_name == :group_parameters_attributes
          add_group(id, attributes)
        else
          add_product(id, attributes)
        end
      end

      def add_product(id, attributes = {})
        parameter = Procedo::Engine::ProductParameter.new(intervention, id, attributes)
        add_parameter(parameter)
      end

      def add_group(id, attributes = {})
        parameter = Procedo::Engine::GroupParameter.new(intervention, id, attributes)
        add_parameter(parameter)
        parameter.parse_params(attributes)
        parameter
      end

      protected

      def add_parameter(parameter)
        unless parameter.is_a?(Procedo::Engine::Parameter)
          fail "Invalid parameter: #{parameter.inspect}"
        end
        @members[parameter.reference_name] ||= []
        @members[parameter.reference_name] << parameter
        parameter
      end
    end
  end
end
