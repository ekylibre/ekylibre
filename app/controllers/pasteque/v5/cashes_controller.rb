class Pasteque::V5::CashesController < Pasteque::V5::BaseController
  manage_restfully only: [:show, :update], model: :cash_session, search_filters: [:id, :cashRegisterId]
end
