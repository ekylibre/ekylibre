module Backend
  module Cells
    class LastIssuesCellsController < Backend::Cells::BaseController
      list(model: :issues, order: 'observed_at DESC', per_page: 10, line_class: :status) do |t|
        t.column :name, url: { controller: '/backend/issues' }
        t.status
        t.column :nature
        t.column :target_name
        t.column :observed_at
        t.column :state
      end

      def show; end
    end
  end
end
