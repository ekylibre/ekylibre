# require 'procedo/procedure/parameter'
# require 'procedo/procedure/handler'

module Procedo
  class Procedure
    # A parameter is used to defined which are the operators, targets, inputs,
    # outputs and tools in procedure.
    class Setting < Procedo::Procedure::Parameter
      include Codeable
      attr_reader :filter, :procedure, :type, :value

      attr_accessor :computed_filter, :type

      TYPES = [:variant, :text].freeze

      code_trees :compute_filter

      def initialize(procedure, name, type, options = {})
        super(procedure, name, options.merge(cardinality: 1))
        @type = type || options[:type]
        unless Setting::TYPES.include?(@type)
          raise ArgumentError, "Unknown setting type: #{@type.inspect}"
        end
        @filter = options[:filter] if options[:filter]
        self.compute_filter = options[:compute_filter] if options[:compute_filter]
      end

      # Returns reflection name for an intervention object
      def reflection_name
        :settings
      end

      def others
        @procedure.parameters.select { |v| v != self }
      end

      TYPES.each do |the_type|
        send(:define_method, "#{the_type}?".to_sym) do
          type == the_type
        end
      end

      # Returns scope hash for unroll
      def scope_hash
        hash = {}
        hash[:of_expression] = @filter unless @filter.blank?
        hash[:of_expression] = @computed_filter unless @computed_filter.nil?
        hash
      end
    end
  end
end
