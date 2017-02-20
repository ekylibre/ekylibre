class RenameProcedureAnimalAntibioticTreatmentToAnimalVeterinaryTreatment < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        execute "UPDATE interventions SET procedure_name = 'animal_veterinary_treatment' WHERE procedure_name = 'animal_antibiotic_treatment'"
      end
      d.down do
        execute "UPDATE interventions SET procedure_name = 'animal_antibiotic_treatment' WHERE procedure_name = 'animal_veterinary_treatment'"
      end
    end
  end
end
