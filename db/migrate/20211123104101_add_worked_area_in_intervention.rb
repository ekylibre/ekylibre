class AddWorkedAreaInIntervention < ActiveRecord::Migration[5.0]
  def change
    add_column :intervention_parameters, :worked_area, :decimal, precision: 19, scale: 4
  end
end
