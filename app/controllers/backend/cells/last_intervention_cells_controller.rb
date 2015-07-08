class Backend::Cells::LastInterventionCellsController < Backend::Cells::BaseController

  def show
    scope = Intervention
    if params[:production] and production = Production.find_by(id: params[:production])
      scope = scope.where(production: production)
    elsif params[:campaign_id] and campaign = Campaign.find(params[:campaign_id])
      scope = scope.of_campaign(campaign)
    elsif current_campaign
      scope = scope.of_campaign(current_campaign)
    end
    @intervention = scope.last
  end

end
