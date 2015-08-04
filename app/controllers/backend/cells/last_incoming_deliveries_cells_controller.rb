class Backend::Cells::LastIncomingDeliveriesCellsController < Backend::Cells::BaseController
  list(model: :incoming_deliveries, order: 'received_at DESC', per_page: 5) do |t|
    t.column :reference_number, url: { controller: '/backend/incoming_deliveries' }
    t.column :received_at
    t.status
    t.column :mode
    t.column :sender
    t.column :purchase, url: { controller: '/backend/purchases' }
  end

  def show
  end
end
