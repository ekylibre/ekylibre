class AddReferenceDataToInterventionParameters < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :reference_data, :jsonb, default: {}
    add_column :intervention_parameters, :using_live_data, :boolean, default: true
  end
end
