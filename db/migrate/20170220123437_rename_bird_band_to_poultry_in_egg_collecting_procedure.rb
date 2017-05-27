class RenameBirdBandToPoultryInEggCollectingProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'poultry'
          FROM interventions
          WHERE (iparam.reference_name = 'bird_band'
            AND interventions.procedure_name = 'egg_collecting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'bird_band'
          FROM interventions
          WHERE (iparam.reference_name = 'poultry'
            AND interventions.procedure_name = 'egg_collecting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
