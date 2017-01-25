module Backend
  module Cells
    class LastProductsCellsController < Backend::Cells::BaseController
      list(model: :animals, conditions: ["#{Animal.table_name}.born_at IS NOT NULL"], order: { born_at: :desc }, per_page: 12) do |t|
        t.column :name, url: { controller: '/backend/animals' }
        # t.column :mother, :url => {controller: "/backend/animals"}
        # t.column :father, :url => {controller: "/backend/animals"}
        t.status
        t.column :born_at
        t.column :sex
      end

      def show; end
    end
  end
end
