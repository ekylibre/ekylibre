module Backend
  module Visualizations
    class InspectionsVisualizationsController < Backend::VisualizationsController
      include Backend::ActivitiesHelper

      respond_to :json

      def show
        dimension = permitted_params[:dimension]
        inspections = Inspection.where(id: permitted_params[:inspections_ids]&.split(','))

        return render json: {} if dimension.blank? || inspections.empty?

        inspection_data = inspection_series(dimension, inspections)

        return render json: {} if inspection_data.blank?

        config = view_context.configure_visualization do |v|
          v.serie :inspection, inspection_data
          v.categories :ready_to_harvest, :inspection, without_ghost_label: true
          v.choropleth :disease_percentage, :inspection, stop_color: "#FF0000"
          v.choropleth :deformity_percentage, :inspection, stop_color: "#FFB300"
        end

        respond_with config
      end

      private
        def permitted_params
          params.permit(:dimension, :inspections_ids)
        end
    end
  end
end
