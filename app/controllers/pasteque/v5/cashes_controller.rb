class Pasteque::V5::CashesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :nil
end
