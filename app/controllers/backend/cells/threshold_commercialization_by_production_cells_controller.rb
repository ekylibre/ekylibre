class Backend::Cells::ThresholdCommercializationByProductionCellsController < Backend::Cells::BaseController
  def show
    if params[:production_id]
      @production = Production.find_by(id: params[:production_id])
    elsif params[:activity_ids] && params[:campaign_ids]
      @production = Production.find_by(campaign_id: params[:campaign_ids], activity_id: params[:activity_ids])
    else
      @production = nil
    end
  end
end
