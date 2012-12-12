class Admin::Cells::DemoBarCellsController < Admin::CellsController

  def show
    max = rand(1_000_000)
    @values = (rand(25)+10).times.inject({}) do |hash, index|
      hash["Month #{index}"] = rand(max)
      hash
    end
  end

end
