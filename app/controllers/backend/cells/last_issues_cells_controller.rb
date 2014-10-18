class Backend::Cells::LastIssuesCellsController < Backend::CellsController

  list(model: :issues, :order => "observed_at DESC", :per_page => 10, line_class: :status) do |t|
    t.column :target_name,  :url => {controller: "/backend/issues"}
    t.column :nature
    t.column :observed_at
    t.status
    t.column :state
  end


  def show
  end

end
