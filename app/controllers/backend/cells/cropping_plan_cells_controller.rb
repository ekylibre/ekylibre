module Backend
  module Cells
    class CroppingPlanCellsController < Backend::Cells::BaseController
      def show
        @campaigns = if params[:campaign_ids]
                       Campaign.find(params[:campaign_ids])
                     elsif params[:campaign_id]
                       Campaign.find(params[:campaign_id])
                     else
                       current_campaign
                     end
      end
    end
  end
end
