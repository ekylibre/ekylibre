class Pasteque::V5::CashMovementsController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show]
end
