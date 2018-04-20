class Backend::Cells::ThresholdCommercializationByProductionCellsController < Backend::Cells::BaseController

  def show
    if params[:production_id]
      @production = Activity.find_by(id: params[:production_id])
    elsif params[:activity_ids] and params[:campaign_ids]
      @production = Activity.where(campaign_id: params[:campaign_ids], id: params[:activity_ids])
    else
      @production = nil
    end
    @campaign = current_campaign
  end

end
