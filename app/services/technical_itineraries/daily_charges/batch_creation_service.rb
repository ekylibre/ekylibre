# frozen_string_literal: true

module TechnicalItineraries
  module DailyCharges
    class BatchCreationService < CreationService
      def initialize(activity_production)
        super(activity_production)
      end

      def perform
        batch = @activity_production.batch
        batch_number = batch.number
        net_surface_area = @activity_production
                             .net_surface_area.convert(:hectare).to_f / batch_number

        batch_number.times do |number|
          unless number.zero?
            @started_at += batch.day_interval.days
          end

          super(@started_at,
                net_surface_area,
                batch_number: batch_number)
        end
      end
    end
  end
end
