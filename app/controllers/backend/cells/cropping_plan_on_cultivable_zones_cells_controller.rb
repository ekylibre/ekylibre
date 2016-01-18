class Backend::Cells::CroppingPlanOnCultivableZonesCellsController < Backend::Cells::BaseController
  def show
    @campaigns = if params[:campaign_ids]
                   Campaign.find(params[:campaign_ids])
                 elsif params[:campaign_id]
                   Campaign.find(params[:campaign_id])
                 else
                   Campaign.currents.last
                 end
  end
end
