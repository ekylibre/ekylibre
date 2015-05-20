class Pasteque::V5::LocationsController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :product
end
