module Backend
  module Cells
    class StockContainerMapCellsController < Backend::Cells::BaseController
      def show
        @variety = params[:variety] || :product
      end
    end
  end
end
