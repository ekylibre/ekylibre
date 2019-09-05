class Backend::Cells::ThresholdCommercializationByProductionCellsController < Backend::Cells::BaseController
  def show
    @production = if params[:production_id]
                    Activity.find_by(id: params[:production_id])
                  elsif params[:activity_ids] && params[:campaign_ids]
                    Activity.where(campaign_id: params[:campaign_ids], id: params[:activity_ids])
                  end
    @campaign = current_campaign
  end
end
