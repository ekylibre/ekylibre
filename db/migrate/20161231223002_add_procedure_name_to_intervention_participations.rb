class AddProcedureNameToInterventionParticipations < ActiveRecord::Migration
  def change
    add_column :intervention_participations, :procedure_name, :string
  end
end
