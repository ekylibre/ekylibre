class Pasteque::V5::RolesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :user
end
