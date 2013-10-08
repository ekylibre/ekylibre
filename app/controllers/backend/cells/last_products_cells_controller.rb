class Backend::Cells::LastProductsCellsController < Backend::CellsController

  list(:model => :animals, :order=>"born_at DESC", :per_page=>5) do |t|
    t.column :name, :url => {:controller => "/backend/animals"}
    t.column :name, :through => :mother, :url => {:controller => "/backend/animals"}
    t.column :name, :through => :father, :url => {:controller => "/backend/animals"}
    t.column :born_at
    t.column :sex
  end


  def show

  end

end
