class Backend::Cells::LastOutgoingDeliveriesCellsController < Backend::Cells::BaseController
  list(model: :outgoing_deliveries, order: 'sent_at DESC', per_page: 5) do |t|
    t.column :number, url: { controller: '/backend/outgoing_deliveries' }
    t.column :reference_number
    t.column :sent_at
    t.status
    t.column :mode
    t.column :transporter
    t.column :sale, url: { controller: '/backend/sales' }
  end

  def show
  end
end
