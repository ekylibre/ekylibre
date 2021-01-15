class HandWeedingProceduresDataMigration < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE intervention_parameters AS ipd
        SET reference_name = 'driver'
      FROM interventions AS i
        INNER JOIN intervention_parameters AS ipi
          ON ipi.intervention_id = i.id
          AND ipi.type = 'InterventionInput'
      WHERE ipd.intervention_id = i.id
        AND i.procedure_name = 'hand_weeding'
        AND ipd.type = 'InterventionDoer';

      UPDATE intervention_parameters AS ip
        SET reference_name = 'plant_medicine'
      FROM interventions AS i
      WHERE ip.intervention_id = i.id
        AND procedure_name = 'hand_weeding'
        AND ip.type = 'InterventionInput';

      UPDATE interventions AS i
        SET procedure_name = 'spraying'
      FROM intervention_parameters AS ip
      WHERE ip.intervention_id = i.id
        AND procedure_name = 'hand_weeding'
        AND ip.type = 'InterventionInput'
    SQL
  end
end
