class AddProcedureNameToInterventionParticipations < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_participations, :procedure_name, :string
  end
end
