module Backend
  module Cells
    class CurrentStocksByVarietyCellsController < Backend::Cells::BaseController
      def show
        @variety = params[:variety] || :product
        @indicator = Onoma::Indicator[params[:indicator] || :net_mass]
        @unit = Onoma::Unit[params[:unit] || @indicator.unit]
      end
    end
  end
end
