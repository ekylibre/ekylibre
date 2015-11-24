module Pasteque
  module V5
    class RolesController < Pasteque::V5::BaseController
      manage_restfully only: [:index, :show], model: :user
    end
  end
end
