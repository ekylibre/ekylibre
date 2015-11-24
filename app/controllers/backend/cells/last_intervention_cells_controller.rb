module Backend
  module Cells
    class LastInterventionCellsController < Backend::Cells::BaseController
      def show
        scope = Intervention
        if params[:production] && production = ActivityProduction.find_by(id: params[:production])
          scope = scope.of_production(production)
        elsif params[:campaign_id] && campaign = Campaign.find(params[:campaign_id])
          scope = scope.of_campaign(campaign)
        elsif current_campaign
          scope = scope.of_campaign(current_campaign)
        end
        @intervention = scope.last
      end
    end
  end
end
