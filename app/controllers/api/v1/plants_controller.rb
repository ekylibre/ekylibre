module Api
  module V1
    # Plants API permits to access plants
    class PlantsController < Api::V1::BaseController
      def index
        @plants = Plant.availables.order(id: :desc)
      end
    end
  end
end
