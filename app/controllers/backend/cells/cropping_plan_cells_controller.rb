class Backend::Cells::CroppingPlanCellsController < Backend::Cells::BaseController
  def show
    if params[:campaign_ids]
      @campaigns = Campaign.find(params[:campaign_ids])
    elsif params[:campaign_id]
      @campaigns = [Campaign.find(params[:campaign_id])]
    else
      @campaigns = [current_campaign]
    end
  end
end
