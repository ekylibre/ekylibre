class Admin::Cells::LastEventsCellsController < Admin::CellsController

  list(:model => :product_events) do |t|
    t.column :name
    t.column :started_at

  end

  def show
  end

end
