module Backend
  module Cells
    class StewardshipCellsController < Backend::Cells::BaseController
      def show
        if params[:campaign_id]
          @campaigns = [Campaign.find(params[:campaign_id])]
        elsif params[:current_campaign_id]
          @campaigns = [Campaign.find(params[:current_campaign_id])]
        else
          @campaigns = [Campaign.current.last]
        end
      end
    end
  end
end
