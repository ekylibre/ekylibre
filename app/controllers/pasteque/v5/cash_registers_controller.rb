class Pasteque::V5::CashRegistersController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :cash, scope: :cash_boxes, search_filters: {id: :id, label: :name}
end
