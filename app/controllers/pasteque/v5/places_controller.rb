class Pasteque::V5::PlacesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :building_division, scope: :floors
end
