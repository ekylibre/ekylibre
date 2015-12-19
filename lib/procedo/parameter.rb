require 'procedo/cardinality'

module Procedo
  # Parameter class is the base class for all parameters types
  class Parameter
    attr_reader :procedure, :name, :group
    attr_accessor :cardinality

    delegate :name, to: :procedure, prefix: true

    def initialize(procedure, name, options = {})
      @procedure = procedure
      @name = name.to_sym
      @group = options[:group]
      @cardinality = Procedo::Cardinality.new(options[:cardinality] || '+')
    end

    def name=(value)
      # TODO: Check name unicity
      @name = value.to_sym
    end

    # Translate the name of the parameter
    def human_name(options = {})
      "procedure_parameters.#{name}".t(options.merge(default: ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize]))
    end
  end
end
