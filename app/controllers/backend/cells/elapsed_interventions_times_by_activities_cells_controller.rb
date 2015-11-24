module Backend
  module Cells
    class ElapsedInterventionsTimesByActivitiesCellsController < Backend::Cells::BaseController
      def show
        if params[:campaign_id] && campaign = Campaign.find(params[:campaign_id])
          @campaign = campaign
        else
          @campaign = current_campaign
        end
      end
    end
  end
end
