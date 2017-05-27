class RewriteAnimalInterventions < ActiveRecord::Migration
  def up
    # animal_housing_mulching
    execute "UPDATE interventions SET actions = 'hygiene' WHERE procedure_name = 'animal_housing_mulching'"
  end
end
