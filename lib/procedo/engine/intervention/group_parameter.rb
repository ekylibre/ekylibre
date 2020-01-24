# require 'procedo/engine/intervention/parameter'
# require 'procedo/engine/intervention/input'
# require 'procedo/engine/intervention/output'
# require 'procedo/engine/intervention/target'
# require 'procedo/engine/intervention/tool'
# require 'procedo/engine/intervention/doer'

module Procedo
  module Engine
    class Intervention
      class GroupParameter < Procedo::Engine::Intervention::Parameter
        CHILDREN_PARAM_NAMES = %i[doers_attributes inputs_attributes
                                  outputs_attributes targets_attributes
                                  tools_attributes group_parameters_attributes].freeze

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          @members = {}.with_indifferent_access
        end

        def parse_params(params)
          CHILDREN_PARAM_NAMES.each do |param_name|
            next unless params[param_name]
            params[param_name].each do |id, attributes|
              # puts "Add #{param_name}: #{id} (#{attributes.inspect})".magenta
              add(param_name, id, attributes)
            end
          end
        end

        def to_hash
          hash = super
          each_member do |parameter|
            param_name = parameter.param_name
            hash[param_name] ||= {}
            hash[param_name][parameter.id.to_s] = parameter.to_hash
          end
          hash
        end

        def to_attributes
          hash = super
          each_member do |parameter|
            param_name = parameter.param_name
            hash[param_name] ||= {}
            hash[param_name][parameter.id.to_s] = parameter.to_attributes
          end
          hash
        end

        def handlers_states
          hash = {}
          each_member do |parameter|
            param_name = parameter.param_name
            next unless parameter.respond_to? :handlers_states
            states = parameter.handlers_states
            next if states.empty?
            hash[param_name] ||= {}
            hash[param_name][parameter.id.to_s] = states
          end
          hash
        end

        def each_member(&_block)
          @members.each do |_reflection, children|
            children.each do |_id, member|
              yield member
            end
          end
        end

        def children(name)
          parameters = []
          each_member do |member|
            parameters << member if member.name == name
          end
          parameters
        end

        def parameters_of_name(name)
          parameters = []
          each_member do |member|
            parameters << member if member.name == name
            if member.respond_to?(:parameters_of_name)
              parameters += member.parameters_of_name(name)
            end
          end
          parameters
        end

        def parameters_of_type(type)
          parameters = []
          each_member do |member|
            parameters << member if member.type.to_sym == type
          end
          parameters
        end

        # Builds and adds a parameter of any type in members
        def add(param_name, id, attributes = {})
          model_name = param_name.to_s.gsub(/_attributes$/, '').singularize
          class_name = 'Procedo::Engine::Intervention::' + model_name.camelize
          parameter = class_name.constantize.new(self, id, attributes)
          add_parameter(parameter)
          if parameter.is_a?(Procedo::Engine::Intervention::GroupParameter)
            parameter.parse_params(attributes)
          end
          parameter
        end

        def impact_with(steps)
          unless steps.size > 1
            raise ArgumentError, 'Invalid steps: got ' + steps.inspect
          end
          @members[steps[0]][steps[1]].impact_with(steps[2..-1])
        end

        protected

        def add_parameter(parameter)
          unless parameter.is_a?(Procedo::Engine::Intervention::Parameter)
            raise "Invalid parameter: #{parameter.inspect}"
          end
          @members[parameter.reference_reflection_name] ||= {}.with_indifferent_access
          @members[parameter.reference_reflection_name][parameter.id] = parameter
          parameter
        end
      end
    end
  end
end
