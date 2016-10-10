class AddActivityIdToPlantDensityAbaci < ActiveRecord::Migration
  def change
    add_reference :plant_density_abaci, :activity
  end
end
