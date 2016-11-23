module Api
  module V1
    # PlantCountings API permits to access plant_density_abaci
    class PlantCountingsController < Api::V1::BaseController
      def create
        plant_counting = PlantCounting.new(permitted_params.merge(creator_id: current_user.id))
        if plant_counting.save
          render json: { id: plant_counting.id }, status: :created
        else
          render json: plant_counting.errors, status: :unprocessable_entity
        end
      end

      protected

      def permitted_params
        super.permit(:comment, :plant_density_abacus_item_id, :average_value, :read_at, :number, :nature, :plant_id, items_attributes: [:value])
      end
    end
  end
end
