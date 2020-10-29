# require 'procedo/engine/intervention/group_parameter'
# require 'procedo/engine/intervention/working_period'

module Procedo
  module Engine
    class Intervention
      attr_reader :procedure
      attr_reader :working_periods

      delegate :name, to: :procedure, prefix: true
      delegate :add, :add_group, :add_product, :to_hash, to: :root_group

      def initialize(attributes = {})
        @attributes = attributes.deep_symbolize_keys
        @procedure = Procedo.find(@attributes[:procedure_name])
        unless @procedure
          raise "Cannot find procedure: #{@attributes[:procedure_name].inspect}"
        end
        @actions = (@attributes[:actions] || []).map(&:to_sym)
        @root_group = Procedo::Engine::Intervention::GroupParameter.new(self, Procedo::Procedure::ROOT_NAME)
        @working_periods = {}.with_indifferent_access
        if @attributes[:working_periods_attributes]
          @attributes[:working_periods_attributes].each do |id, attributes|
            add_working_period(id, attributes)
          end
        end
        # Parse doers, inputs...
        @root_group.parse_params(@attributes)
      end

      def to_hash
        hash = { procedure_name: @procedure.name, working_periods_attributes: {} }
        @working_periods.each do |id, period|
          hash[:working_periods_attributes][id] = period.to_hash
        end
        @root_group.each_member do |parameter|
          param_name = parameter.param_name
          hash[param_name] ||= {}
          hash[param_name][parameter.id.to_s] = parameter.to_hash
        end
        hash
      end

      def to_attributes
        hash = { procedure_name: @procedure.name, working_periods_attributes: {} }
        @working_periods.each do |id, period|
          hash[:working_periods_attributes][id] = period.to_attributes
        end
        @root_group.each_member do |parameter|
          param_name = parameter.param_name
          hash[param_name] ||= {}
          hash[param_name][parameter.id.to_s] = parameter.to_attributes
        end
        hash
      end

      def handlers_states
        hash = {}
        @root_group.each_member do |parameter|
          param_name = parameter.param_name
          next unless parameter.respond_to? :handlers_states
          states = parameter.handlers_states
          next if states.empty?
          hash[param_name] ||= {}
          hash[param_name][parameter.id.to_s] = states
        end
        hash
      end

      def procedure_states
        hash = {}
        @procedure.parameters.each do |parameter|
          param_name = parameter.name
          concerned_params = @root_group.parameters_of_name(param_name)
          display_method = parameter.display_status if parameter.respond_to? :display_status
          hash[param_name] = { display: Functions.send(display_method, concerned_params) } if display_method
        end
        hash
      end

      delegate :to_json, to: :to_hash

      def add_working_period(id, attributes = {})
        period = Procedo::Engine::Intervention::WorkingPeriod.new(id, attributes)
        @working_periods[period.id] = period
      end

      def working_duration
        @working_periods.map(&:duration).sum || 0.0
      end

      def interpret(tree, env = {})
        Interpreter.interpret(self, tree, env)
      end

      def parameter_set(name)
        Procedo::Engine::Set.new(self, procedure.find!(name))
      end

      def parameters_of_name(name)
        @root_group.parameters_of_name(name.to_sym)
      end

      def parameters_of_type(type)
        @root_group.parameters_of_type(type.to_sym)
      end

      # Impact changes
      def impact_with!(steps)
        steps = steps.to_s.split(/[\[\]]+/) unless steps.is_a?(Array)
        unless steps.size > 1
          raise ArgumentError, 'Invalid steps: got ' + steps.inspect
        end
        if steps.first == 'working_periods'
          @working_periods[steps[1]].impact_with(steps[2..-1])
        else
          @root_group.impact_with(steps)
        end
      end

      def working_periods_parameter
        @working_periods.values.collect(&:to_hash)
      end

      private

      attr_reader :root_group
    end
  end
end
