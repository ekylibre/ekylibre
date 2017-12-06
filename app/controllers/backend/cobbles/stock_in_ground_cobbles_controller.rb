module Backend
  module Cobbles
    class StockInGroundCobblesController < Backend::Cobbles::BaseController
      def show
        @stock_in_ground_cobble = Activity.find(params[:id])

        @dimension = params[:dimension]
        @last_inspection = @stock_in_ground_cobble.inspections.last
        @measure_symbol  = Nomen::Unit.find(@last_inspection.user_quantity_unit(@dimension)).symbol
        @yield_symbol    = Nomen::Unit.find(@last_inspection.user_per_area_unit(@dimension)).symbol
      end
    end
  end
end
