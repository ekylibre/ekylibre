class Backend::Cells::StewardshipCellsController < Backend::Cells::BaseController
  def show
    if params[:campaign_id]
      @campaigns = [Campaign.find(params[:campaign_id])]
    elsif params[:current_campaign_id]
      @campaigns = [Campaign.find(params[:current_campaign_id])]
    else
      @campaigns = [Campaign.currents.last]
    end
  end
end
