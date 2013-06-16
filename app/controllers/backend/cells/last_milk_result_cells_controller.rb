class Backend::Cells::LastMilkResultCellsController < Backend::CellsController

  list(:model => :product_indicator_data, :order => "created_at DESC", :per_page => 10) do |t|
    t.column :indicator#, :url => true
    t.column :name, :through => :product, :url => {:controller => "'/backend/products'"}
    t.column :value
  end

  def show
  end

end
