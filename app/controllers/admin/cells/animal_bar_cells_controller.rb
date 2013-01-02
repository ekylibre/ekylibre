class Admin::Cells::AnimalBarCellsController < Admin::CellsController

  def show
    @values = AnimalGroup.all.inject({}) do |hash, group|
    hash[group.name] = group.animals.count
    hash   
    end
  end

end
