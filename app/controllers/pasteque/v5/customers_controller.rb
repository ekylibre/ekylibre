class Pasteque::V5::CustomersController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :entity, scope: :clients
end
