module Backend
  module Cells
    class LastPurchasesOrdersCellsController < Backend::Cells::BaseController
      list(model: :purchase_orders, order: 'created_at DESC', per_page: 5) do |t|
        t.column :number, url: { controller: '/backend/purchase_orders' }
        t.column :created_at
        t.column :state_label
        t.column :amount, currency: true
      end

      def show; end
    end
  end
end
