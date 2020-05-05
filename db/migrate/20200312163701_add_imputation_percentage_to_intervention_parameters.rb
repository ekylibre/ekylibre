class AddImputationPercentageToInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :imputation_ratio, :decimal, precision: 19, scale: 4

    reversible do |dir|
      dir.up do
        # COMPUTE quantity_value & quantity_unit_name for target from working_zone with good SRID
        execute <<~SQL
          UPDATE intervention_parameters AS ip
            SET quantity_unit_name = 'square_meter',
                quantity_indicator_name = 'net_surface_area',
                quantity_value = CASE
                                 WHEN p.srid IS NULL OR p.srid = 4326
                                   THEN ST_Area(working_zone::GEOGRAPHY)
                                 ELSE
                                   ST_Area(ST_Transform(working_zone, COALESCE(p.srid)))
                                 END
            FROM (SELECT CASE
                         WHEN string_value = 'WGS84' THEN 4326
                         WHEN string_value = 'RGF93' THEN 2154
                         WHEN string_value ~ '_' THEN SPLIT_PART(string_value, '_', 2)::INTEGER
                         ELSE 0 END AS srid
                  FROM preferences WHERE name = 'map_measure_srs' LIMIT 1) AS p
            WHERE ip.type = 'InterventionTarget'
            AND ip.working_zone IS NOT NULL;
        SQL

        # COMPUTE imputation_ratio for each intervention with target quantity_value
        execute <<~SQL
          UPDATE intervention_parameters AS ip
            SET imputation_ratio = (quantity_value /
                                            (SELECT SUM(quantity_value)
                                             FROM intervention_parameters AS ips
                                             WHERE ips.intervention_id = ip.intervention_id
                                               AND ips.type = 'InterventionTarget'
                                               AND ips.quantity_unit_name = 'square_meter'
                                               AND ips.quantity_indicator_name = 'net_surface_area'
                                               AND ips.quantity_value IS NOT NULL
                                               AND ips.quantity_value <> 0
                                               AND ips.working_zone IS NOT NULL)
                                   )
            WHERE ip.type = 'InterventionTarget'
              AND ip.quantity_unit_name = 'square_meter'
              AND ip.quantity_indicator_name = 'net_surface_area'
              AND ip.quantity_value IS NOT NULL
              AND ip.quantity_value <> 0
              AND ip.working_zone IS NOT NULL;
        SQL

        # update view to add imputation_ratio
        execute <<~SQL
          CREATE OR REPLACE VIEW activities_interventions AS
            SELECT
              DISTINCT interventions.id AS intervention_id,
              activities.id AS activity_id,
              interventions.started_at AS intervention_started_at,
              interventions.working_duration AS intervention_working_duration,
              SUM(intervention_parameters.imputation_ratio) AS imputation_ratio,
              (interventions.working_duration * SUM(intervention_parameters.imputation_ratio)) AS intervention_activity_working_duration
            FROM activities
              JOIN activity_productions ON (activity_productions.activity_id = activities.id)
              JOIN products ON (products.activity_production_id = activity_productions.id)
              JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
              JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
            GROUP BY interventions.id, activities.id, interventions.working_duration, interventions.started_at
            ORDER BY interventions.id;
        SQL

        execute <<~SQL
          CREATE OR REPLACE VIEW activity_productions_interventions AS
            SELECT
              DISTINCT interventions.id AS intervention_id,
              products.activity_production_id,
              interventions.started_at AS intervention_started_at,
              interventions.working_duration AS intervention_working_duration,
              SUM(intervention_parameters.imputation_ratio) AS imputation_ratio,
              (interventions.working_duration * SUM(intervention_parameters.imputation_ratio)) AS intervention_activity_working_duration
            FROM activity_productions
              JOIN products ON (products.activity_production_id = activity_productions.id)
              JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
              JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
            GROUP BY interventions.id, products.activity_production_id, interventions.working_duration, interventions.started_at
            ORDER BY interventions.id;
        SQL

        execute <<~SQL
          CREATE OR REPLACE VIEW campaigns_interventions AS
            SELECT
              DISTINCT campaigns.id AS campaign_id,
              interventions.id AS intervention_id,
              SUM(intervention_parameters.imputation_ratio) AS imputation_ratio
            FROM interventions
              JOIN intervention_parameters ON (intervention_parameters.intervention_id = interventions.id)
              JOIN products ON (products.id = intervention_parameters.product_id)
              JOIN activity_productions ON (products.activity_production_id = activity_productions.id)
              JOIN campaigns ON (activity_productions.campaign_id = campaigns.id)
            GROUP BY campaigns.id, interventions.id
            ORDER BY campaigns.id;
        SQL

      end

      dir.down do

        execute <<~SQL
          CREATE OR REPLACE VIEW activities_interventions AS
            SELECT
              DISTINCT interventions.id AS intervention_id,
              activities.id AS activity_id
            FROM activities
              JOIN activity_productions ON (activity_productions.activity_id = activities.id)
              JOIN products ON (products.activity_production_id = activity_productions.id)
              JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
              JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
            ORDER BY interventions.id;
        SQL

        execute <<~SQL
          CREATE OR REPLACE VIEW activity_productions_interventions AS
            SELECT
              DISTINCT interventions.id AS intervention_id,
              products.activity_production_id
            FROM activity_productions
              JOIN products ON (products.activity_production_id = activity_productions.id)
              JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
              JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
            ORDER BY interventions.id;
        SQL

        execute <<~SQL
          CREATE OR REPLACE VIEW campaigns_interventions AS
            SELECT DISTINCT campaigns.id AS campaign_id,
              interventions.id AS intervention_id
            FROM interventions
              JOIN intervention_parameters ON (intervention_parameters.intervention_id = interventions.id)
              JOIN products ON (products.id = intervention_parameters.product_id)
              JOIN activity_productions ON (products.activity_production_id = activity_productions.id)
              JOIN campaigns ON (activity_productions.campaign_id = campaigns.id)
            ORDER BY campaigns.id;
        SQL

      end
    end

  end
end
