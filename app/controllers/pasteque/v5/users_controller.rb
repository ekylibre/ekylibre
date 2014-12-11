class Pasteque::V5::UsersController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show]
end
