module Backend
  module Cells
    class UnbalancedSuppliersCellsController < Backend::Cells::BaseController
      list(model: :entities, conditions: { supplier: true, id: 'Entity.joins(:economic_situation).merge(EconomicSituation.unbalanced).pluck(:id)'.c }, order: { created_at: :desc }, per_page: 10) do |t|
        t.column :full_name, url: { controller: '/backend/entities' }
        t.column :nature
        t.column :balance
        t.column :supplier_accounting_balance
      end

      def show; end
    end
  end
end
