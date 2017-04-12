module Backend
  module Cells
    class AccountancyBalanceCellsController < Backend::Cells::BaseController
      def show
        f = current_user.current_financial_year
        if f
          @financial_year = f
          @started_on = f.started_on
          @stopped_on = f.stopped_on
        end
      end
    end
  end
end
