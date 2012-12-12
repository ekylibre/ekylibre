class Admin::Cells::PlaceholderCellsController < Admin::CellsController

  def show
    @count = rand(4)+1
  end

end
