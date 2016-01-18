module Backend
  module Cells
    class CroppingPlanOnCultivableZonesCellsController < Backend::Cells::BaseController
      def show
        @campaigns = if params[:campaign_ids]
                       Campaign.find(params[:campaign_ids])
                     elsif params[:campaign_id]
                       Campaign.find(params[:campaign_id])
                     else
                       Campaign.current.last
                     end
      end
    end
  end
end
