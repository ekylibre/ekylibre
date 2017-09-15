module Backend
  module Cells
    class ProductionCostCellsController < Backend::Cells::BaseController
      def show
        @activity_production = ActivityProduction.find(params[:id])
      end
    end
  end
end
