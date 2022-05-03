module Backend
  module Cells
    class LastDocumentsCellsController < Backend::Cells::BaseController
      list(model: :documents, order: { created_at: :desc }, per_page: 10) do |t|
        t.column :name, url: { controller: '/backend/documents' }
        t.column :nature
        t.column :number, hidden: true
        t.column :created_at
        t.column :key, hidden: true
        t.column :ocr_presence, datatype: :boolean
        t.column :uploaded, hidden: true
        t.column :file_pages_count, class: "center-align"
        t.column :file_fingerprint, hidden: true
      end

      def show; end
    end
  end
end
