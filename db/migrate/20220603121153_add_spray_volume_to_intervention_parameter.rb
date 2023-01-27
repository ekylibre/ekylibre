class AddSprayVolumeToInterventionParameter < ActiveRecord::Migration[5.0]
  def change
    add_column :intervention_parameters, :spray_volume_value, :decimal, precision: 19, scale: 4
  end
end
