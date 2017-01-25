class AddDeadColumnToInterventionParameter < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :dead, :boolean, null: false, default: false
  end
end
