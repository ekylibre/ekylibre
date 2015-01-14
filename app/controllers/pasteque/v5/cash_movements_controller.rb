class Pasteque::V5::CashMovementsController < Pasteque::V5::BaseController
  update_filters = {
    cashId: :cash_id,
    note: :comment
  }
  manage_restfully only: [:create], model: :cash_transfer, update_filters: update_filters
end
