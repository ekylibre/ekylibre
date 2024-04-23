module Backend
  module Visualizations
    class CadastralParcelsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = view_context.configure_visualization do |v|
          v.serie :cadastral_parcels, (params[:bounds] ? compute_dataset(params[:bounds]) : [])
          v.optional :cadastral_parcels, :cadastral_parcels, add_to_map: params[:add_to_map] # , fill_color: 'yellow', without_ghost_label: false
        end

        respond_with config
      end

      private

        def compute_dataset(bounds)
          RegisteredCadastralParcel.in_bounding_box(bounds).map do |cadastral_parcel|
            feature = {}.with_indifferent_access
            feature[:shape_color] = "#EFFA03"
            content = []
            content << { label: :name.tl, value: cadastral_parcel.label }
            if cadastral_parcel.mutations.present?
              feature[:shape_color] = "#FAD803"
              cadastral_parcel.mutations.each do |mutation|
                content << { label: mutation[:mutation_id], value: mutation[:mutation_on]&.l }
                content << { label: :price.tl, value: mutation[:mutation_price]&.round_l(precision: 2, currency: 'EUR') }
              end
            end
            feature[:popup] = { content: content, header: true }
            feature[:name] = cadastral_parcel.label
            feature[:nature] = cadastral_parcel.section
            feature[:shape] = cadastral_parcel.shape
            feature
          end
        end
    end
  end
end
