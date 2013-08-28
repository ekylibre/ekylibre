class Backend::Cells::CalendarCellsController < Backend::CellsController

  def show
    @purchases = Purchase.to_a
  end

end
