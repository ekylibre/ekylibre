class UpdateAnimalChangingParameters < ActiveRecord::Migration
  # remove old target parameter 'land_parcel' in plant_watering intervention
  def up
    execute "UPDATE intervention_parameters i SET type = 'InterventionTarget' WHERE i.reference_name = 'animal' and i.type = 'InterventionInput' and i.intervention_id IN (SELECT id FROM interventions WHERE procedure_name = 'animal_group_changing')"
  end
  def down
    execute "UPDATE intervention_parameters i SET type = 'InterventionInput' WHERE i.reference_name = 'animal' and i.type = 'InterventionTarget' and i.intervention_id IN (SELECT id FROM interventions WHERE procedure_name = 'animal_group_changing')"
  end
end
