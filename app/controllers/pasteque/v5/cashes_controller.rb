class Pasteque::V5::CashesController < Pasteque::V5::BaseController
  manage_restfully only: [:show, :update], model: :cash_session, search_filters: {id: :id, cash_register: :cash_id}

  def search
    correspondence = {
      cashRegisterId: :cash_id,
      dateStart: :started_at,
      dateStop: :stopped_at
    }
    criterias = params.slice(:cashRegisterId, :dateStart, :dateStop).map{|k,v|[correspondence[k], v]}
    @records = model.find_by(criterias)
    render template: "layouts/pasteque/v5/index", locals:{output_name: 'cash', partial: 'cashes/cash'}
  end
end
