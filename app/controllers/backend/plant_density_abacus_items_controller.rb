module Backend
  # Manage PlantDensityAbacusItem records
  class PlantDensityAbacusItemsController < Backend::BaseController
    manage_restfully only: [:new]

    unroll :plants_count, :seeding_density_value, plant_density_abacus: :seeding_density_unit
  end
end
