class Backend::Cells::LastDocumentsCellsController < Backend::Cells::BaseController

  list(model: :documents, order: {archived_at: :desc}, per_page: 10) do |t|
    t.column :name
    t.column :archived_at, url: {controller: "/backend/documents"}
    t.column :nature
    t.column :key, hidden: true
    t.column :uploaded
    t.column :file_pages_count
    t.column :file_fingerprint, hidden: true
  end

  def show
  end

end
