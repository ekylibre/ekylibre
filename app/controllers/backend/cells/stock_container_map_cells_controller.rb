class Backend::Cells::StockContainerMapCellsController < Backend::Cells::BaseController
  def show
    @variety = params[:variety] || :product
  end
end
