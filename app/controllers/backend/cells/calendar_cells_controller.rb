class Backend::Cells::CalendarCellsController < Backend::CellsController

  def show
    @purchases = Purchase.all
  end

end
