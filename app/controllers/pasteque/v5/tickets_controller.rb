class Pasteque::V5::TicketsController < Pasteque::V5::BaseController
  search_filters = {
      ticketId: :id,
      cashId: :cash_session_id,
      dateStart: :created_at,
      dateStop: :closed_on,
      customerId: :third_id,
      userId: :originator_id
  }
  manage_restfully only: [:index, :show, :destroy, :update, :search], model: :affair, scope: :tickets, search_filters: search_filters

  def open
    @records = model.tickets.open
    render template: "layouts/pasteque/v5/index", locals:{output_name: 'tickets', partial_path: 'tickets/ticket'}
  end
end
