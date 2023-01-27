class RenameWorkedZoneInIntervention < ActiveRecord::Migration[5.1]
  def change
    rename_column :intervention_parameters, :worked_area, :working_zone_area_value
  end
end
