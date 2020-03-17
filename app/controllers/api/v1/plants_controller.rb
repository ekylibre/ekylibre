module Api
  module V1
    # Plants API permits to access plants
    class PlantsController < Api::V1::BaseController
      def index
        if modified_since = params[:modified_since]
          plants = Plant.where('updated_at > ?', modified_since.to_date).includes(activity_production: :activity)
        else
          plants = Plant.all.includes(activity_production: :activity)
        end
        render 'api/v1/plants/index.json', locals: { plants: plants }
      end
    end
  end
end
