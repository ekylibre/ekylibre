class UpdateWorkflow < ActiveRecord::Migration[5.0]
  def change
    add_column :intervention_templates, :workflow_unit, :string
    rename_column :intervention_templates, :workflow, :workflow_value
    add_column :technical_itineraries, :plant_density, :decimal, precision: 19, scale: 4
  end
end
