class RenamePlantWateringInstallationTarget < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      # change procedure name harvesting to harvesting_with_plant_or_land_parcel
      # only for land_parcel as a target in harvesting intervention
      dir.up do
        execute <<~SQL
          UPDATE intervention_parameters AS ip
            SET reference_name = 'cultivation'
            FROM interventions AS i
            WHERE ip.intervention_id = i.id
            AND i.procedure_name = 'plant_watering_installation'
            AND ip.type = 'InterventionTarget'
            AND ip.reference_name = 'zone';
        SQL
      end

      dir.down do
        execute <<~SQL
        UPDATE intervention_parameters AS ip
          SET reference_name = 'zone'
          FROM interventions AS i
          WHERE ip.intervention_id = i.id
          AND i.procedure_name = 'plant_watering_installation'
          AND ip.type = 'InterventionTarget'
          AND ip.reference_name = 'cultivation';
        SQL
      end

    end
  end
end
