class ChangeMechanicalFertilizingProcedureName < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE interventions SET procedure_name='fertilizing' WHERE interventions.procedure_name='mechanical_fertilizing'"
  end

  def down
    execute "UPDATE interventions SET procedure_name='mechanical_fertilizing' WHERE interventions.procedure_name='fertilizing'"
  end
end
