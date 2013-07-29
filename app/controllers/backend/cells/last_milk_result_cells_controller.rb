class Backend::Cells::LastMilkResultCellsController < Backend::CellsController

  list(:model => :product_indicator_data,:conditions => ["product_id = 668"], :order => "created_at DESC", :per_page => 10) do |t|
    t.column :indicator#, :url => true
    t.column :name, :through => :product, :url => {:controller => "'/backend/products'"}
    t.column :value
    t.column :measure_unit
    t.column :measured_at
  end

  def show
  end

end
