class Pasteque::V5::TicketsController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show, :destroy, :update], model: :affair, scope: :tickets

  def search
    correspondence = {
      ticketId: :id,
      cashId: :cash_session_id,
      dateStart: :created_at,
      dateStop: :closed_on,
      customerId: :third_id,
      userId: :originator_id
    }.with_indifferent_access
    criterias = params.slice(correspondence.keys).map{|k,v|[correspondence[k], v]}.to_h
    @records = model.where(criterias)
    render template: "layouts/pasteque/v5/index", locals:{output_name: 'tickets', partial_path: 'tickets/ticket'}
  end
  def open
    @records = model.tickets.open
    render template: "layouts/pasteque/v5/index", locals:{output_name: 'tickets', partial_path: 'tickets/ticket'}
  end
end
