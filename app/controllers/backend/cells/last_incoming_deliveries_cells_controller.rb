class Backend::Cells::LastIncomingDeliveriesCellsController < Backend::CellsController

  list(:model => :incoming_deliveries,:order=>"received_at DESC", :per_page=>5) do |t|
    t.column :reference_number, :url => {:controller => "'/backend/incoming_deliveries'"}
    t.column :received_at
    t.column :name, :through => :mode
    t.column :name, :through => :sender
    t.column :number, :through => :purchase, :url => {:controller => "'/backend/purchases'"}
  end


  def show

  end

end
