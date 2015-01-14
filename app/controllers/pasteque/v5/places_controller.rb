class Pasteque::V5::PlacesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :building_division, scope: :floors, output_name: 'floor', partial_path: 'places/floor'
end
