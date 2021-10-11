# frozen_string_literal: true

module TechnicalItineraries
  module DailyCharges
    class DefaultCreationService < CreationService
      def initialize(activity_production)
        super(activity_production)
      end

      def perform
        net_surface_area = @activity_production
                             .net_surface_area
                             .convert(:hectare)
                             .to_f

        super(@started_at, net_surface_area)
      end
    end
  end
end
