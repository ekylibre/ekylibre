class Backend::Cells::LastDocumentArchivesCellsController < Backend::Cells::BaseController

  list(:model => :document_archive, :order => "archived_at DESC", :per_page => 10) do |t|
    t.column :archived_at, :url => {controller: "/backend/document_archives"}
    t.column :document
    t.column :file_pages_count
  end

  def show
  end

end
