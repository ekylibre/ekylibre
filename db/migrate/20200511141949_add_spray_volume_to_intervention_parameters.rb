class AddSprayVolumeToInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :spray_volume, :decimal
  end
end
