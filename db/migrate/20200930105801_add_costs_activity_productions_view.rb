class AddCostsActivityProductionsView < ActiveRecord::Migration[4.2]
  def change
    reversible do |d|
      d.up do
        execute <<-SQL
          CREATE OR REPLACE VIEW activity_productions_interventions_costs AS
            SELECT
              activity_productions.id AS activity_production_id,
              interventions.id AS intervention_id,
              intervention_targets.product_id AS target_id,
              intervention_costings.inputs_cost * intervention_targets.imputation_ratio AS inputs,
              intervention_costings.doers_cost * intervention_targets.imputation_ratio AS doers,
              intervention_costings.tools_cost * intervention_targets.imputation_ratio AS tools,
              intervention_costings.receptions_cost * intervention_targets.imputation_ratio AS receptions,
              (intervention_costings.inputs_cost + intervention_costings.doers_cost + intervention_costings.tools_cost + intervention_costings.receptions_cost) * intervention_targets.imputation_ratio AS total
            FROM
              activity_productions
            INNER JOIN products ON products.activity_production_id = activity_productions.id
            INNER JOIN intervention_parameters AS intervention_targets
              ON intervention_targets.product_id = products.id
              AND intervention_targets.type = 'InterventionTarget'
            INNER JOIN interventions ON interventions.id = intervention_targets.intervention_id
            INNER JOIN intervention_costings ON interventions.costing_id = intervention_costings.id
            WHERE interventions.state != 'rejected' AND interventions.nature = 'record';

          CREATE RULE delete_activity_productions_interventions_costs AS ON DELETE TO activity_productions_interventions_costs DO INSTEAD NOTHING
        SQL
      end

      d.down do
        execute 'DROP VIEW IF EXISTS activity_productions_interventions_costs;'
      end
    end
  end
end
