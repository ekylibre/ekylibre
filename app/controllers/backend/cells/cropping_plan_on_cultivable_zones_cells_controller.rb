class Backend::Cells::CroppingPlanOnCultivableZonesCellsController < Backend::CellsController

  def show
    # GET DATA
    # for last campaign, show each production with product support and area
    @campaigns = params[:campaigns] || Campaign.currents.last
  end

end
