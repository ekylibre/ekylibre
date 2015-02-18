class Backend::Cells::ThresholdCommercializationByProductionCellsController < Backend::Cells::BaseController

  def show
    if params[:activity_ids] and params[:campaign_ids]
      @production = Production.where(campaign_id: params[:campaign_ids], activity_id: params[:activity_ids]).first rescue nil
    else
      @production = nil
    end
  end

end
