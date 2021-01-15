class AddDeadColumnToInterventionParameter < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :dead, :boolean, null: false, default: false
  end
end
