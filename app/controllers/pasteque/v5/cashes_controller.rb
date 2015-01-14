class Pasteque::V5::CashesController < Pasteque::V5::BaseController
  update_filters = {
    id: :id,
    cashRegisterId: :cash_id,
    sequence: :sequence_id,
    openDate: :started_at,
    closeDate: :stopped_at,
    openCash: :noticed_start_amount,
    closeCash: :noticed_stop_amount,
    expectedCash: :expected_stop_amount
  }
  search_filters = {
    cashRegisterId: :cash_id,
    dateStart: :started_at,
    dateStop: :stopped_at
  }
  manage_restfully only: [:show, :update, :search], model: :cash_session, get_filters: {id: :id, cashRegisterId: :cash_id}, update_filters: update_filters, search_filter: search_filters

  def zticket
    @record = CashSession.find(params[:id]).zticket
    render partial: 'pasteque/v5/cashes/zticket', locals:{zticket: @record}
  end
end
