class AddActivityIdToPlantDensityAbaci < ActiveRecord::Migration[4.2]
  def change
    add_reference :plant_density_abaci, :activity
  end
end
