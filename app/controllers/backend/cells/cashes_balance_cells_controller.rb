class Backend::Cells::CashesBalanceCellsController < Backend::Cells::BaseController

  def show
    @cashes = Cash.order(:name)
  end

end
