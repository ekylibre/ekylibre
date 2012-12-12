class Admin::Cells::DemoBarCellsController < Admin::CellsController

  def show
    @values = (rand(25)+10).times.inject({}) do |hash, index|
      hash["Month #{index}"] = rand(200)
      hash
    end
  end

end
