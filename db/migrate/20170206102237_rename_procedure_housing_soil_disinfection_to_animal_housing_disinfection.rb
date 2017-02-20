class RenameProcedureHousingSoilDisinfectionToAnimalHousingDisinfection < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        execute "UPDATE interventions SET procedure_name = 'animal_housing_disinfection' WHERE procedure_name = 'housing_soil_disinfection'"
      end
      d.down do
        execute "UPDATE interventions SET procedure_name = 'housing_soil_disinfection' WHERE procedure_name = 'animal_housing_disinfection'"
      end
    end
  end
end
