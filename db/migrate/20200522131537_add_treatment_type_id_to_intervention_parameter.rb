class AddTreatmentTypeIdToInterventionParameter < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :treatment_type_id, :string
  end
end
