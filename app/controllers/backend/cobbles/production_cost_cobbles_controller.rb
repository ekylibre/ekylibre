module Backend
  module Cobbles
    class ProductionCostCobblesController < Backend::Cobbles::BaseController
      def show
        @activity_production = ActivityProduction.find(params[:id])
      end
    end
  end
end
