class AddDeadColumnToInterventionParameter < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :dead, :boolean, default: false
  end
end
