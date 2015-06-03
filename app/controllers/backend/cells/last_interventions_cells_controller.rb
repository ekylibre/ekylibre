class Backend::Cells::LastInterventionsCellsController < Backend::Cells::BaseController

  def show
    scope = Intervention
    if params[:production] and production = Production.find_by(id: params[:production])
      scope = scope.where(production: production)
    elsif params[:campaign_id] and campaign = Campaign.find(params[:campaign_id])
      scope = scope.of_campaign(campaign)
    end
    @intervention = scope.last
  end

end
