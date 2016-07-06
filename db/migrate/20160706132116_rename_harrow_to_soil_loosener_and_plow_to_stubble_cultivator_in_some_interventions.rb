class RenameHarrowToSoilLoosenerAndPlowToStubbleCultivatorInSomeInterventions < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'soil_loosener'
          FROM interventions
          WHERE (iparam.reference_name = 'harrow'
            AND interventions.procedure_name = 'uncompacting'
            AND iparam.intervention_id = interventions.id)
        SQL
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'stubble_cultivator'
          FROM interventions
          WHERE (iparam.reference_name = 'plow'
            AND interventions.procedure_name = 'superficial_plowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
          UPDATE
            intervention_parameters AS iparam
            SET reference_name = 'harrow'
            FROM interventions
            WHERE (iparam.reference_name = 'soil_loosener'
              AND interventions.procedure_name = 'uncompacting'
              AND iparam.intervention_id = interventions.id)
        SQL
        execute <<-SQL
          UPDATE
            intervention_parameters AS iparam
            SET reference_name = 'plow'
            FROM interventions
            WHERE (iparam.reference_name = 'stubble_cultivator'
              AND interventions.procedure_name = 'superficial_plowing'
              AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
