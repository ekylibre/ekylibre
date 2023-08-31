module Backend
  module Cells
    class SubscriptionsIndicatorsCellsController < Backend::Cells::BaseController
      def show
        f = current_user.current_financial_year
        if f
          @financial_year = f
          @started_on = f.started_on
          @stopped_on = f.stopped_on
          @started_at = f.started_on.to_time
          @stopped_at = f.stopped_on.to_time
        end
      end
    end
  end
end
