class Pasteque::V5::TicketsController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show, :destroy, :update], model: :affair, scope: :tickets

  def search
    correspondence = {
      ticketId: :id,
      cashId: nil,
      dateStart: :started_at,
      dateStop: :stopped_at
    }.with_indifferent_access
    criterias = params.slice(correspondence.keys).map{|k,v|[correspondence[k], v]}.to_h
    @records = model.where(criterias)
    render template: "layouts/pasteque/v5/index", locals:{output_name: 'cash', partial_path: 'cashes/cash'}
  end
end
