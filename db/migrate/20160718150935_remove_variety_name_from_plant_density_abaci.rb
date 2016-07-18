class RemoveVarietyNameFromPlantDensityAbaci < ActiveRecord::Migration
  def change
    remove_column :plant_density_abaci, :variety_name
  end
end
