module Backend
  module Cells
    class LastWorkersCellsController < Backend::Cells::BaseController
      list(model: :products,  conditions: { type: 'Worker' }, order: { created_at: :desc }, per_page: 10) do |t|
        t.column :name, url: { controller: '/backend/workers' }
        t.column :work_number
        t.column :number
        t.column :variant
        t.column :variety
        t.column :description
      end

      def show; end
    end
  end
end
