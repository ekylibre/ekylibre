class FixWorkingPeriodToActivityInterventions < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE VIEW activities_interventions AS
            SELECT
              DISTINCT interventions.id AS intervention_id,
              activities.id AS activity_id,
              intervention_working_periods.started_at AS intervention_started_at,
              intervention_working_periods.duration AS intervention_working_duration,
              ROUND(sum(intervention_parameters.imputation_ratio), 2) AS imputation_ratio,
              (intervention_working_periods.duration * ROUND(SUM(intervention_parameters.imputation_ratio), 2)) AS intervention_activity_working_duration
            FROM activities
              JOIN activity_productions ON (activity_productions.activity_id = activities.id)
              JOIN products ON (products.activity_production_id = activity_productions.id)
              JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
              JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
              JOIN intervention_working_periods ON (interventions.id = intervention_working_periods.intervention_id)
            GROUP BY interventions.id, activities.id, intervention_working_periods.started_at, intervention_working_periods.duration
            ORDER BY interventions.id, activities.id, intervention_working_periods.started_at;
        SQL

        execute <<~SQL
          CREATE OR REPLACE VIEW activity_productions_interventions AS
            SELECT
              DISTINCT interventions.id AS intervention_id,
              products.activity_production_id,
              intervention_working_periods.started_at AS intervention_started_at,
              intervention_working_periods.duration AS intervention_working_duration,
              ROUND(SUM(intervention_parameters.imputation_ratio), 2) AS imputation_ratio,
              (intervention_working_periods.duration * ROUND(SUM(intervention_parameters.imputation_ratio), 2)) AS intervention_activity_working_duration
            FROM activity_productions
              JOIN products ON (products.activity_production_id = activity_productions.id)
              JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
              JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
              JOIN intervention_working_periods ON (interventions.id = intervention_working_periods.intervention_id)
            GROUP BY interventions.id, products.activity_production_id, intervention_working_periods.started_at, intervention_working_periods.duration
            ORDER BY interventions.id, products.activity_production_id, intervention_working_periods.started_at;
        SQL

      end

      dir.down do

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

      end
    end
  end
end
