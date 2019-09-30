class RemoveVarietyNameFromPlantDensityAbaci < ActiveRecord::Migration[4.2]
  def change
    revert { add_column :plant_density_abaci, :variety_name, :string }
  end
end
