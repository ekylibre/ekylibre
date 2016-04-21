module Api
  module V1
    # Plants API permits to access plants
    class PlantsController < Api::V1::BaseController
      def index
        render json: Plant.order(id: :desc).limit(25), status: :ok
      end
    end
  end
end
