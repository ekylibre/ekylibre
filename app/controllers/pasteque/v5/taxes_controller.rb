class Pasteque::V5::TaxesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show]
end
