class Backend::Cells::CalendarCellsController < Backend::CellsController

  def show
    @interventions = Intervention.all
  end

end
