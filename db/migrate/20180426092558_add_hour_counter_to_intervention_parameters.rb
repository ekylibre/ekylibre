class AddHourCounterToInterventionParameters < ActiveRecord::Migration
  def up
    add_column :intervention_parameters, :hour_counter, :decimal
  end

  def down
    remove_column :intervention_parameters, :hour_counter, :decimal
  end
end
