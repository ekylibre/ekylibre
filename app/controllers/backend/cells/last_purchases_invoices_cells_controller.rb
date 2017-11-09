module Backend
  module Cells
    class LastPurchasesInvoicesCellsController < Backend::Cells::BaseController
      list(model: :purchase_invoices, order: 'created_at DESC', per_page: 5) do |t|
        t.column :number, url: { controller: '/backend/purchase_invoices' }
        t.column :created_at
        t.status
        t.column :amount, currency: true
      end

      def show; end
    end
  end
end
