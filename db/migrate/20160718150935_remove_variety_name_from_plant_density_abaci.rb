class RemoveVarietyNameFromPlantDensityAbaci < ActiveRecord::Migration
  def change
    revert { add_column :plant_density_abaci, :variety_name, :string }
  end
end
