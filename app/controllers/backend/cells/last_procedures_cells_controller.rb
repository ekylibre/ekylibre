class Backend::Cells::LastEventsCellsController < Backend::CellsController

  list(:model => :logs) do |t|
    t.column :observed_at
    t.column :description
  end

  def show
  end

end
