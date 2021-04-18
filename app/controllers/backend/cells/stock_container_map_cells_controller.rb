module Backend
  module Cells
    class StockContainerMapCellsController < Backend::Cells::BaseController
      def show
        @campaigns = if params[:campaign_ids]
                       Campaign.find(params[:campaign_ids])
                     elsif params[:campaign_id]
                       Campaign.find(params[:campaign_id])
                     else
                       current_campaign
                     end

        @url_params = {
                       campaigns: @campaigns,
                       visualization: params[:visualization]
                     }
      end
    end
  end
end
