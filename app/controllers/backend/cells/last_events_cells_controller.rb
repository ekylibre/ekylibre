class Backend::Cells::LastEventsCellsController < Backend::CellsController

  list(:model => :events) do |t|
    t.column :started_at
    t.column :description
  end

  def show
  end

end
