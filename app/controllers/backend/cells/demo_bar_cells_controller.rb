class Backend::Cells::DemoBarCellsController < Backend::CellsController

  def show
    max = rand(1_000_000)
    @values = (rand(7)+5).times.inject({}) do |hash, index|
      hash["Month #{index}"] = rand(max)
      hash
    end
  end

end
