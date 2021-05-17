# frozen_string_literal: true

module ActivityProductions
  class CostsCalculation
    def compute_costs(activity_production, campaign)
      activity_production_costs = ActiveRecord::Base.connection.execute <<~SQL
        SELECT
          activity_productions.id,
          SUM(intervention_costings.inputs_cost * intervention_targets.imputation_ratio) AS inputs,
          SUM(intervention_costings.doers_cost * intervention_targets.imputation_ratio) AS doers,
          SUM(intervention_costings.tools_cost * intervention_targets.imputation_ratio) AS tools,
          SUM(intervention_costings.receptions_cost * intervention_targets.imputation_ratio) AS receptions,
          SUM((intervention_costings.inputs_cost + intervention_costings.doers_cost + intervention_costings.tools_cost + intervention_costings.receptions_cost) * intervention_targets.imputation_ratio) AS total
        FROM
          activity_productions
        INNER JOIN products ON products.activity_production_id = activity_productions.id
        INNER JOIN intervention_parameters AS intervention_targets
          ON intervention_targets.product_id = products.id
          AND intervention_targets.type = 'InterventionTarget'
        INNER JOIN interventions ON interventions.id = intervention_targets.intervention_id
        INNER JOIN campaigns_interventions ON campaigns_interventions.intervention_id = interventions.id
        INNER JOIN intervention_costings ON interventions.costing_id = intervention_costings.id
        WHERE activity_productions.id = #{activity_production.id}
        AND campaigns_interventions.campaign_id = #{campaign.id}
        -- only with interventions with nature record and state is not rejected
        AND interventions.state != 'rejected'
        AND interventions.nature = 'record'
        GROUP BY activity_productions.id;
      SQL

      return { inputs: 0, doers: 0, tools: 0, receptions: 0, total: 0 } if activity_production_costs.values.empty?

      activity_production_costs.first.symbolize_keys.except(:id).transform_values(&:to_i)
    end
  end
end
