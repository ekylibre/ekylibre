class Backend::Cells::LastPurchasesCellsController < Backend::CellsController

  list(:model => :purchases,:order=>"created_on DESC", :per_page=>5) do |t|
    t.column :number, :url => {:controller => "/backend/purchases"}
    t.column :created_on
    t.status
    t.column :state_label
    t.column :amount, currency: true
  end


  def show

  end

end
