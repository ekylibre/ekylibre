module Backend
  module Cells
    class TraceabilityCheckCellsController < Backend::Cells::BaseController
      def show
        @campaign = if params[:campaign_id]
                      Campaign.find(params[:campaign_id])
                    else
                      current_campaign
                    end
      end
    end
  end
end
