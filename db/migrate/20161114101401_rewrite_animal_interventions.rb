class RewriteAnimalInterventions < ActiveRecord::Migration
  def change
    # animal_housing_mulching
    execute "UPDATE interventions SET actions = 'hygiene' WHERE procedure_name = 'animal_housing_mulching'"
  end
end
