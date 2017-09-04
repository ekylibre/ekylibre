module Backend
  # Manage PlantDensityAbacus records
  class PlantDensityAbaciController < Backend::BaseController
    manage_restfully except: :index
  end
end
