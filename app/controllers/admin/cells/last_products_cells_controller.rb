class Admin::Cells::LastProductsCellsController < Admin::CellsController

  list(:model => :animals, :order=>"born_at DESC", :per_page=>5) do |t|
    t.column :name
    t.column :name, :through => :mother
    t.column :name, :through => :father
    t.column :born_at
    t.column :sex
  end

  def show
  end

end
