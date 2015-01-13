class Pasteque::V5::CashesController < Pasteque::V5::BaseController
  manage_restfully only: [:show, :update], model: :cash_session, search_filters: {id: :id, cashRegisterId: :cash_id}

  def search
    correspondence = {
      cashRegisterId: :cash_id,
      dateStart: :started_at,
      dateStop: :stopped_at
    }.with_indifferent_access
    criterias = params.slice(:cashRegisterId, :dateStart, :dateStop).map{|k,v|[correspondence[k], v]}.to_h
    @records = model.where(criterias)
    render template: "layouts/pasteque/v5/index", locals:{output_name: 'cash', partial_path: 'cashes/cash'}
  end

  def zticket
    @record = CashSession.find(params[:id]).zticket
    render partial: 'pasteque/v5/cashes/zticket', locals:{zticket: @record}
  end

end
