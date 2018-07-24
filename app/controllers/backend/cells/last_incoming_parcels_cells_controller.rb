module Backend
  module Cells
    class LastIncomingParcelsCellsController < Backend::Cells::BaseController
      list(model: :receptions, conditions: { nature: 'incoming', state: %w[draft] }, order: 'given_at DESC', per_page: 5) do |t|
        t.column :number, url: { controller: '/backend/receptions' }
        t.column :reference_number, url: { controller: '/backend/receptions' }
        t.column :sender, url: { controller: '/backend/entities' }
        t.column :given_at
        t.status
        t.column :delivery, url: { controller: '/backend/deliveries' }
        t.column :delivery_mode, hidden: true
        # t.column :purchase, url: { controller: '/backend/purchases' }, hidden: true
      end

      def show; end
    end
  end
end
