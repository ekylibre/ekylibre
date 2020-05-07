module Backend
  module Visualizations
    class NonTreatmentAreasVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        distances = params[:required_value] ? [params[:required_value]] : RegisteredPhytosanitaryUsage::UNTREATED_BUFFER_AQUATIC_VALUES
        config = view_context.configure_visualization do |v|
          distances.each do |distance|
            v.serie "nta_#{distance}", params[:bounds] ? compute_dataset(params[:bounds], distance) : []
            v.optional :aquatic_nta.tl(distance: distance), "nta_#{distance}", required_value: distance, add_to_map: params[:add_to_map] == distance.to_s
          end
        end

        respond_with config
      end

      private

        def compute_dataset(bounds, distance)
          RegisteredHydroItem.in_bounding_box(bounds).map do |hydro_item|
            content = []
            content << { label: :name.tl, value: hydro_item.name } if hydro_item.name
            content << { label: :nature.tl, value: hydro_item.nature }
            feature = { popup: { content: content, header: true } }
            feature[:name] = ''
            feature[:shape] = hydro_item.geometry.buffer(distance)
            feature
          end
        end
    end
  end
end
