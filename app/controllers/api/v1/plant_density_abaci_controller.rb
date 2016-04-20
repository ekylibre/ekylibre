module Api
  module V1
    # PlantDensityAbaci API permits to access plant_density_abacuss
    class PlantDensityAbaciController < Api::V1::BaseController
      def index
        render json: PlantDensityAbacus.order(id: :desc).limit(25), status: :ok
      end

      def show
        @plant_density_abacus = PlantDensityAbacus.find_by(id: params[:id])
        unless abacus
          render json: { message: 'Not found' }, status: :not_found
          return
        end
      end
      
      protected

      def permitted_params
        params.permit(:name, :germination_percentage, :sampling_length_unit, :seeding_density_unit, :variety_name)
      end
    end
  end
end
