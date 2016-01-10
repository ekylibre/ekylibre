# require 'procedo/engine/intervention_parameter'
# require 'procedo/engine/intervention_input'
# require 'procedo/engine/intervention_output'
# require 'procedo/engine/intervention_target'
# require 'procedo/engine/intervention_tool'
# require 'procedo/engine/intervention_doer'

module Procedo
  module Engine
    class InterventionGroupParameter < Procedo::Engine::InterventionParameter
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
            # puts "Add #{param_name}: #{id} (#{attributes.inspect})".magenta
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

      def each_member(&_block)
        @members.each do |_reflection, children|
          children.each do |_id, member|
            yield member
          end
        end
      end

      # Builds and adds a parameter of any type in members
      def add(param_name, id, attributes = {})
        model_name = param_name.to_s.gsub(/_attributes$/, '').singularize
        class_name = 'Procedo::Engine::Intervention' + model_name.camelize
        parameter = class_name.constantize.new(intervention, id, attributes)
        add_parameter(parameter)
        if parameter.is_a?(Procedo::Engine::InterventionGroupParameter)
          parameter.parse_params(attributes)
        end
        parameter
      end

      def impact_with(steps)
        if steps.size == 1
          impact(step)
        elsif steps.size >= 2
          puts steps.inspect.red
          # puts @members.inspect.cyan
          @members[steps[0]][steps[1]].impact_with(steps[2..-1])
        else
          fail 'Invalid steps: ' + steps.inspect
        end
      end

      protected

      def add_parameter(parameter)
        unless parameter.is_a?(Procedo::Engine::InterventionParameter)
          fail "Invalid parameter: #{parameter.inspect}"
        end
        @members[parameter.reference_reflection_name] ||= {}.with_indifferent_access
        @members[parameter.reference_reflection_name][parameter.id] = parameter
        parameter
      end
    end
  end
end
