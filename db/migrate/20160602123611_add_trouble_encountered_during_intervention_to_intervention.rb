class AddTroubleEncounteredDuringInterventionToIntervention < ActiveRecord::Migration
  def change
    add_column :interventions, :maintenance_nature, :string
    add_column :interventions, :trouble_encountered, :boolean, null: false, default: false
    add_column :interventions, :trouble_description, :string
  end
end
