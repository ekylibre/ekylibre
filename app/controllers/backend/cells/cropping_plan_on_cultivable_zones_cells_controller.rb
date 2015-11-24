module Backend
  module Cells
    class CroppingPlanOnCultivableZonesCellsController < Backend::Cells::BaseController
      def show
        if params[:campaign_ids]
          @campaigns = Campaign.find(params[:campaign_ids])
        elsif params[:campaign_id]
          @campaigns = Campaign.find(params[:campaign_id])
        else
          @campaigns = Campaign.currents.last
        end
      end
    end
  end
end
