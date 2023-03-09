# frozen_string_literal: true

module Interventions
  class BuildInterventionInteractor
    attr_reader :intervention, :attributes, :error, :parameters, :options

    def initialize(parameters, options)
      @parameters = parameters
      @options = options
    end

    def run
      raise StandardError.new('Parameters are missings') if parameters.empty?

      @intervention = ::Intervention.find_or_initialize_by(id: parameters[:id])
      parameters[:procedure_name] ||= @intervention.procedure_name

      @attributes = Interventions::Computation::Compute
                            .new(parameters: parameters)
                            .perform(options: options)

      @intervention.attributes = attributes
      @intervention.save!
      @intervention
    rescue ActiveRecord::RecordInvalid => exception
      raise
    rescue StandardError => exception
      @error = exception
      nil
    end

    def success?
      @error.nil?
    end

    def fail?
      !success
    end
  end
end
