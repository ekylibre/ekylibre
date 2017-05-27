class RenameHousingToAnimalHousingInAnimalHousingDisinfectionProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'animal_housing'
          FROM interventions
          WHERE (iparam.reference_name = 'housing'
            AND interventions.procedure_name = 'animal_housing_disinfection'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'housing'
          FROM interventions
          WHERE (iparam.reference_name = 'animal_housing'
            AND interventions.procedure_name = 'animal_housing_disinfection'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
