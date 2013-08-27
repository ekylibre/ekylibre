class Backend::Cells::ProductPieCellsController < Backend::CellsController

  def show
    @values = ProductNature.limit(10).inject({}) do |hash, nature|
    hash[nature.name] = nature.products.count
    hash
    end
  end

end