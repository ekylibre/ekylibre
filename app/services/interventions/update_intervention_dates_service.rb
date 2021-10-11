# frozen_string_literal: true

module Interventions
  class UpdateInterventionDatesService
    attr_reader :new_date, :intervention, :model

    def initialize(new_date, intervention)
      @new_date = new_date
      @intervention = intervention
    end

    def perform(model)
      @model = model

      new_started_at = new_attribute_value(:started_at)
      new_stopped_at = new_attribute_value(:stopped_at)

      @model.update_columns(started_at: new_started_at, stopped_at: new_stopped_at)
    end

    private

      def new_attribute_value(attribute)
        return @model.send(attribute) + days_between_dates.day if later_date?
        return @model.send(attribute) - days_between_dates.day if previous_date?
      end

      def later_date?
        @new_date > @intervention.started_at.to_date
      end

      def previous_date?
        @new_date < @intervention.started_at.to_date
      end

      def days_between_dates
        started_at = @intervention.started_at.to_date

        return (@new_date - started_at).to_i if later_date?
        return (started_at - @new_date).to_i if previous_date?
      end
  end
end
