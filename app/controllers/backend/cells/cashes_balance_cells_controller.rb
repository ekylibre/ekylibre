module Backend
  module Cells
    class CashesBalanceCellsController < Backend::Cells::BaseController
      def show
        @cashes = Cash.order(:name)
      end
    end
  end
end
