module Pasteque
  module V5
    class LocationsController < Pasteque::V5::BaseController
      manage_restfully only: [:index, :show], model: :product
    end
  end
end
