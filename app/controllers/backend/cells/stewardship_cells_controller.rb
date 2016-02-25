module Backend
  module Cells
    class StewardshipCellsController < Backend::Cells::BaseController
      def show
        @campaign = if params[:campaign_id]
                      Campaign.find(params[:campaign_id])
                    elsif current_campaign
                      current_campaign
                    else
                      Campaign.current.last
                     end
      end
    end
  end
end
