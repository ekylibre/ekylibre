class Backend::Cells::LastIncidentsCellsController < Backend::CellsController

  list(:model => :incidents, :order=>"observed_at DESC", :per_page=>10, line_class: :status) do |t|
    t.column :name,  :url => {:controller => "/backend/incidents"}
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end


  def show

  end

end
