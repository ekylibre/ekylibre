class Backend::Cells::ProductBarCellsController < Backend::CellsController

  def show
    @values = ProductGroup.all.inject({}) do |hash, group|
    hash[group.name] = group.products.count
    hash
    end
  end

end
