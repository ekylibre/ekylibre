module Api
  module V1
    # PlantDensityAbaci API permits to access plant_density_abaci
    class PlantDensityAbaciController < Api::V1::BaseController
      def index
        @plant_density_abaci = PlantDensityAbacus.order(id: :desc)
      end

      def show
        @plant_density_abacus = PlantDensityAbacus.find_by(id: params[:id])
        unless @plant_density_abacus
          render json: { message: 'Not found' }, status: :not_found
          return false
        end
      end
    end
  end
end
