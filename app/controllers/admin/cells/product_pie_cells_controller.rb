class Admin::Cells::ProductPieCellsController < Admin::CellsController

  def show
    @values = ProductGroup.all.inject({}) do |hash, group|
    hash[group.name] = group.products.count
    hash
    end
  end

end