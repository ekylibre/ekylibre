class Pasteque::V5::CashMvtsController < Pasteque::V5::BaseController
  update_filters = {
    cashId: :cash_id,
    note: :comment
  }
  #manage_restfully only: [:create], model: :cash_transfer, update_filters: update_filters
  def move
    render status: :unprocessable_entity, json: {status: :rej, content: nil}
  end
end
