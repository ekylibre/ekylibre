class AddEntryAndHarvestToInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :allowed_entry_factor, :integer, default: nil
    add_column :intervention_parameters, :allowed_harvest_factor, :integer, default: nil
  end
end
