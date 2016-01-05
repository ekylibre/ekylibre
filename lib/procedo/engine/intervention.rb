require 'procedo/engine/group_parameter'
require 'procedo/engine/working_period'

module Procedo
  module Engine
    class Intervention
      attr_reader :procedure

      delegate :name, to: :procedure, prefix: true
      delegate :add, :add_group, :add_product, :to_hash, to: :root_group

      def initialize(attributes = {})
        puts attributes.inspect.green
        @attributes = attributes.deep_symbolize_keys
        @procedure = Procedo.find(@attributes[:procedure_name])
        unless @procedure
          fail "Cannot find procedure: #{@attributes[:procedure_name].inspect}"
        end
        @actions = (@attributes[:actions] || []).map(&:to_sym)
        @root_group = Procedo::Engine::GroupParameter.new(self, Procedo::Procedure::ROOT_NAME)
        @working_periods = []
        @attributes[:working_periods_attributes].each do |id, attributes|
          add_working_period(id, attributes)
        end
        # Parse doers, inputs...
        @root_group.parse_params(@attributes)
      end

      def to_hash
        hash = { procedure_name: @procedure.name, working_periods_attributes: {} }
        @working_periods.each do |period|
          hash[:working_periods_attributes][period.id] = period.to_hash
        end
        @root_group.each_member do |parameter|
          param_name = parameter.param_name
          hash[param_name] ||= {}
          hash[param_name][parameter.id.to_s] = parameter.to_hash
        end
        hash
      end

      delegate :to_json, to: :to_hash

      def add_working_period(id, attributes = {})
        period = Procedo::Engine::WorkingPeriod.new(id, attributes)
        @working_periods << period
      end

      def working_duration
        @working_periods.map(&:duration).sum || 0.0
      end

      # Impact changes
      def impact!(updater_name)
        object = find_object(updater_name)
        object.impact! if object
      end

      private

      attr_reader :root_group

      # Find a working_period, or a parameters
      def find_object(_name)
        nil
      end
    end
  end
end
