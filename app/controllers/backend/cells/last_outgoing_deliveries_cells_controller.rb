class Backend::Cells::LastOutgoingDeliveriesCellsController < Backend::CellsController

  list(:model => :outgoing_deliveries,:order=>"received_at DESC", :per_page=>5) do |t|
    t.column :reference_number, :url => {:controller => "/backend/outgoing_deliveries"}
    t.column :sent_at
    t.column :mode
    t.column :transporter
    t.column :sale, :url => {:controller => "/backend/sales"}
  end


  def show

  end

end
