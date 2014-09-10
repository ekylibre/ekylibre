class Backend::Cells::MapCellsController < Backend::CellsController

  def show
    if params[:campaign_ids]
      @campaigns = Campaign.find(params[:campaign_ids])
    else
      @campaigns = Campaign.currents.last
    end
  end

end
