class Admin::Cells::LastEventsCellsController < Admin::CellsController

  list(:model => :animal_events) do |t|
    t.column :name, :through => :animal, :url => true
    t.column :name, :through => :nature, :url => true

  end

  def show
    @values = (rand(15)+10).times.collect{ rand(200) }
  end

end
