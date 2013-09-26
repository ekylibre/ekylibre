class Backend::Cells::CroppingPlanOnCultivableLandParcelsCellsController < Backend::CellsController

  def show
    # GET DATA
    # for last campaign, show each production with product support and area
    @campaigns = Campaign.currents.last
  end

end
