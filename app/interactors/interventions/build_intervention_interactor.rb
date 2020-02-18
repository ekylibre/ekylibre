module Interventions
  class BuildInterventionInteractor

    attr_reader :intervention, :attributes, :error, :parameters, :options

    def initialize(parameters, options)
      @parameters = parameters
      @options = options
    end

    def run
      raise StandardError.new('Parameters are missings') if parameters.empty?

      @attributes = Interventions::Computation::Compute
                            .new(parameters: parameters)
                            .perform(options: options)

      @intervention = ::Intervention.new(@attributes)
      @intervention.save!
      @intervention

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
