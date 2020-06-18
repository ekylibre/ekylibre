class RenameHarvestingIntervention < ActiveRecord::Migration
  def change
    reversible do |dir|
      # change procedure name harvesting to harvesting_with_plant_or_land_parcel
      # only for land_parcel as a target in harvesting intervention
      dir.up do
        execute <<~SQL
          UPDATE interventions AS i
            SET procedure_name = 'harvesting_with_plant_or_land_parcel'
            FROM intervention_parameters AS ip
            JOIN products AS p ON ip.product_id = p.id
            WHERE ip.intervention_id = i.id
            AND i.procedure_name = 'harvesting'
            AND ip.type = 'InterventionTarget'
            AND ip.reference_name = 'plant'
            AND p.type = 'LandParcel';
        SQL
      end

      dir.down do
        execute <<~SQL
          UPDATE interventions AS i
            SET procedure_name = 'harvesting'
            WHERE i.procedure_name = 'harvesting_with_plant_or_land_parcel';
        SQL
      end

    end
  end
end
