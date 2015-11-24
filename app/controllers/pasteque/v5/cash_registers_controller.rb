module Pasteque
  module V5
    class CashRegistersController < Pasteque::V5::BaseController
      manage_restfully only: [:index, :show], model: :cash, scope: :cash_boxes, get_filters: { id: :id, label: :name }
    end
  end
end
