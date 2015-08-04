class Backend::Cells::CurrentStocksByVarietyCellsController < Backend::Cells::BaseController
  def show
    @variety = params[:variety] || :product
    @indicator = Nomen::Indicators[params[:indicator] || :net_mass]
    @unit = Nomen::Units[params[:unit] || @indicator.unit]
  end
end
