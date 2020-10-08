module Activities
  class CostsCalculation

    def compute_costs(activity, campaign)
      activity_costs = ActiveRecord::Base.connection.execute <<~SQL
        SELECT
          activity_id,
          campaign_id,
          SUM(inputs) AS inputs,
          SUM(doers) AS doers,
          SUM(tools) AS tools,
          SUM(receptions) AS receptions,
          SUM(total) AS total
        FROM (
          SELECT DISTINCT
            activity_productions.id,
            activity_productions.activity_id AS activity_id,
            activity_productions_campaigns.campaign_id AS campaign_id,
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
          INNER JOIN intervention_costings ON interventions.costing_id = intervention_costings.id
          INNER JOIN activity_productions_campaigns
            ON activity_productions_campaigns.activity_production_id = activity_productions.id
          -- only with interventions with nature record and state is not rejected
          WHERE interventions.state != 'rejected'
          AND interventions.nature = 'record'
          GROUP BY activity_productions.id, activity_productions_campaigns.campaign_id
        ) subquery
        WHERE activity_id = #{activity.id}
        AND campaign_id = #{campaign.id}
        GROUP BY activity_id, campaign_id;
      SQL

      return { inputs: 0, doers: 0, tools: 0, receptions: 0, total: 0 } if activity_costs.values.empty?

      activity_costs.first.symbolize_keys
        .except(:id, :activity_id, :campaign_id)
        .transform_values(&:to_i)
    end
  end
end
