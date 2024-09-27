module Backend
  module Cells
    class LastIncomingParcelsCellsController < Backend::Cells::BaseController
      list(model: :receptions, conditions: { nature: 'incoming', state: %w[given] }, order: 'given_at DESC', per_page: 5) do |t|
        t.column :number, url: { controller: '/backend/receptions' }
        t.column :reference_number, url: { controller: '/backend/receptions' }
        t.column :sender, url: { controller: '/backend/entities' }
        t.column :given_at
        t.status
        t.column :state_label, hidden: true
        t.column :delivery, url: { controller: '/backend/deliveries' }, hidden: true
        t.column :delivery_mode, hidden: true
      end

      def show; end
    end
  end
end
