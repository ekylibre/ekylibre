# frozen_string_literal: true

module TechnicalItineraries
  module DailyCharges
    class IrregularBatchCreationService < CreationService
      def initialize(activity_production)
        super(activity_production)
      end

      def perform
        irregular_batches = @activity_production
                              .batch
                              .irregular_batches
        irregular_batches.each do |irregular_batch|
          super(irregular_batch.estimated_sowing_date,
                irregular_batch.area,
                irregular_batch_id: irregular_batch.id)
        end
      end
    end
  end
end
