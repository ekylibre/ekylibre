module Backend
  module Cells
    class LastOutgoingParcelsCellsController < Backend::Cells::BaseController
      list(model: :parcels, conditions: { nature: 'outgoing', state: %w[ordered in_preparation prepared] }, order: 'given_at DESC', per_page: 5) do |t|
        t.column :number, url: { controller: '/backend/parcels' }
        t.column :recipient, url: { controller: '/backend/entities' }
        t.column :given_at
        t.status
        t.column :delivery, url: { controller: '/backend/deliveries' }
        t.column :delivery_mode, hidden: true
        t.column :sale, url: { controller: '/backend/sales' }, hidden: true
      end

      def show; end
    end
  end
end
