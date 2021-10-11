class HistoricalRecoveryTargetsDistributions < ActiveRecord::Migration[4.2]
  def up
    execute 'UPDATE products SET activity_production_id = NULL WHERE activity_production_id NOT IN (SELECT id FROM activity_productions)'

    add_activity_production_to_land_parcels
    add_activity_production_to_plants
  end

  def down; end

  def add_activity_production_to_land_parcels
    execute "UPDATE products AS lp
    SET activity_production_id = ap.id
    FROM activity_productions AS ap
      JOIN activities AS a ON (a.id = ap.activity_id)
    WHERE lp.type = 'LandParcel'
      AND lp.activity_production_id IS NULL
      AND lp.name ILIKE '%' || a.name || '%'
      AND (lp.name ILIKE '%n°' || ap.rank_number || '%' OR lp.name ILIKE '%#' || ap.rank_number || '%')".gsub(/[[:space:]]+/, ' ')
  end

  def add_activity_production_to_plants
    execute "UPDATE products
     SET activity_production_id = lp.activity_production_id
     FROM (SELECT land_parcels.activity_production_id, outputs.product_id AS plant_id
             FROM products AS land_parcels
               JOIN intervention_parameters AS targets ON (targets.product_id = land_parcels.id AND targets.type = 'InterventionTarget' AND reference_name = 'land_parcel')
               JOIN intervention_parameters AS groups ON (targets.group_id = groups.id)
               JOIN intervention_parameters AS outputs ON (outputs.group_id = groups.id AND outputs.type = 'InterventionOutput')
             WHERE land_parcels.type = 'LandParcel'
               AND land_parcels.activity_production_id IS NOT NULL) AS lp
     WHERE products.type = 'Plant'
       AND products.activity_production_id IS NULL
       AND products.id = lp.plant_id".gsub(/[[:space:]]+/, ' ')
  end
end
