class RenamePreparationToDisinfectantInAnimalHousingDisinfectionProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'disinfectant'
          FROM interventions
          WHERE (iparam.reference_name = 'preparation'
            AND interventions.procedure_name = 'animal_housing_disinfection'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'preparation'
          FROM interventions
          WHERE (iparam.reference_name = 'disinfectant'
            AND interventions.procedure_name = 'animal_housing_disinfection'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
