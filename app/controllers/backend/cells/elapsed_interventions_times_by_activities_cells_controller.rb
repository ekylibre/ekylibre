module Backend
  module Cells
    class ElapsedInterventionsTimesByActivitiesCellsController < Backend::Cells::BaseController
      def show
        @campaign = if params[:campaign_id] && campaign = Campaign.find(params[:campaign_id])
                      campaign
                    else
                      current_campaign
                    end
      end
    end
  end
end
