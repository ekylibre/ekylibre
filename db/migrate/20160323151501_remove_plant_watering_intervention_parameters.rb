class RemovePlantWateringInterventionParameters < ActiveRecord::Migration
  # remove old target parameter 'land_parcel' in plant_watering intervention
  def up
    execute "DELETE FROM intervention_parameters i WHERE i.reference_name = 'land_parcel' and i.type = 'InterventionTarget' and i.intervention_id IN (SELECT id FROM interventions WHERE procedure_name = 'plant_watering')"
  end
end
