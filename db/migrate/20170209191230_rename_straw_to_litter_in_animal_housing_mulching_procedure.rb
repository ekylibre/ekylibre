class RenameStrawToLitterInAnimalHousingMulchingProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'litter'
          FROM interventions
          WHERE (iparam.reference_name = 'straw'
            AND interventions.procedure_name = 'animal_housing_mulching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'straw'
          FROM interventions
          WHERE (iparam.reference_name = 'litter'
            AND interventions.procedure_name = 'animal_housing_mulching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
