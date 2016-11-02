class RenamePlantToCultivationInPlantMulchingProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'plant_mulching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'plant_mulching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
