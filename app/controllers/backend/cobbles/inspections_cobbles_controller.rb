module Backend
  module Cobbles
    class InspectionsCobblesController < Backend::Cobbles::BaseController
      def show
        @activity = Activity.find_by(id: permitted_params[:id])

        activity_crops = Plant
                          .joins(:inspections)
                          .where(activity_production_id: @activity.productions.map(&:id),
                                dead_at: nil)
                          .where.not(inspections: { forecast_harvest_week: nil })
                          .uniq

        @crops = initialize_grid(activity_crops, decorate: true)
      end

      private

        def permitted_params
          params.permit(:id)
        end
    end
  end
end
