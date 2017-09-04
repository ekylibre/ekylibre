module Backend
  module Cells
    class LastMovementsCellsController < Backend::Cells::BaseController
      list(model: :product_movements, order: { started_at: :desc }, per_page: 10) do |t|
        t.column :work_name, label: :name, through: :product, url: { controller: '/backend/products' }
        t.column :population
        t.column :unit_name, through: :product
        t.column :delta
        t.column :started_at
        t.column :intervention, url: { controller: '/backend/interventions', id: 'RECORD.intervention.id'.c }
        t.column :container, hidden: true
      end

      def show; end
    end
  end
end
