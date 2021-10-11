# frozen_string_literal: true

module Interventions
  class UpdateInterventionDatesInteractor
    def self.call(params)
      interactor = new(params)
      interactor.run
      interactor
    end

    attr_reader :new_date, :intervention, :error

    def initialize(params)
      @new_date = Date.parse(params[:day])
      @intervention = Intervention.find(params[:id])
    end

    def run
      return if @intervention.nil?

      begin
        @intervention.working_periods.each do |working_period|

          Interventions::UpdateInterventionDatesService
            .new(@new_date, @intervention)
            .perform(working_period)
        end

        Interventions::UpdateInterventionDatesService
          .new(@new_date, @intervention)
          .perform(@intervention)
      rescue StandardError => exception
        fail!(exception.message)
      end
    end

    def success?
      @error.nil?
    end

    def fail?
      !@error.nil?
    end

    private

      def fail!(error)
        @error = error
      end
  end
end
