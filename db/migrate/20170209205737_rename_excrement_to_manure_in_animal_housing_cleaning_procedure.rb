class RenameExcrementToManureInAnimalHousingCleaningProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'manure'
          FROM interventions
          WHERE (iparam.reference_name = 'excrement'
            AND interventions.procedure_name = 'animal_housing_cleaning'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'excrement'
          FROM interventions
          WHERE (iparam.reference_name = 'manure'
            AND interventions.procedure_name = 'animal_housing_cleaning'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
