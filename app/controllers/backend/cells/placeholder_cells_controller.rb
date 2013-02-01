class Backend::Cells::PlaceholderCellsController < Backend::CellsController

  def show
    @count = rand(4)+1
  end

end
