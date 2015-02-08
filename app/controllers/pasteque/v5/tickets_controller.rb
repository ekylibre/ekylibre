class Pasteque::V5::TicketsController < Pasteque::V5::BaseController
  search_filters = {
    ticketId: :id,
    cashId: :cash_session_id,
    dateStart: :created_at,
    dateStop: :closed_on,
    customerId: :third_id,
    userId: :originator_id
  }
  update_filters = {
    id: :id,
    date: :started_at,
    cashId: :cash_id,
    ticketId: :affair_id,
    userId: :user_id,
    customerId: :customer_id,
    type: :nature,
    custCount: :count,
    tariffAreaId: :catalog_id,
    payments: :incoming_payments,
    lines: :affairs
  }
  manage_restfully except: [:new, :edit], model: :affair, scope: :tickets, search_filters: search_filters, update_filters: update_filters

  def open
    @records = model.tickets.openeds
    render template: "layouts/pasteque/v5/index", locals: {output_name: 'tickets', partial_path: 'tickets/ticket'}
  end

  protected

  def permitted_params
    params.require(:ticket).permit!
  end

end
