module Activities
  module LeftJoinable
    extend ActiveSupport::Concern

    included do
      # This scope include in the Activity::ActiveRecord_Relation
      # issues_count and opened_issues_count for each activities
      scope :left_join_issues_count_of_campaign, lambda { |campaign|
        joins(
          <<~SQL
            LEFT JOIN (
              SELECT activity_productions.activity_id AS activity_id,
                     -- count issues and opened issues
                     COUNT(issues.*) AS count,
                     SUM(CASE WHEN issues.state = 'opened' THEN 1 ELSE 0 END) AS opened_count
               FROM issues
               INNER JOIN products
                 ON products.id = issues.target_id
               INNER JOIN activity_productions
                 ON activity_productions.id = products.activity_production_id
               INNER JOIN activity_productions_campaigns
                 ON activity_productions.id = activity_productions_campaigns.activity_production_id
               AND activity_productions_campaigns.campaign_id = #{campaign.id}
              GROUP BY activity_productions.activity_id
            ) issues ON issues.activity_id = activities.id
          SQL
        ).select(
          <<~SQL
            activities.*,
            COALESCE(issues.count, 0) AS issues_count,
            COALESCE(issues.opened_count, 0) AS opened_issues_count
          SQL
        )
      }

      # This scope include in the Activity::ActiveRecord_Relation
      # working_duration for each activities
      scope :left_join_working_duration_of_campaign, lambda { |campaign|
        joins(
          <<~SQL
            LEFT JOIN (
              SELECT interventions.activity_id AS activity_id,
                     SUM(interventions.working_duration) AS working_duration
              FROM (
                SELECT DISTINCT
                  interventions.id AS id,
                  interventions.working_duration AS working_duration,
                  activity_productions.activity_id AS activity_id
                FROM activity_productions
                INNER JOIN products
                  ON products.id = activity_productions.support_id
                INNER JOIN intervention_parameters AS intervention_targets
                  ON intervention_targets.type = 'InterventionTarget'
                  AND intervention_targets.product_id = products.id
                INNER JOIN interventions
                  ON interventions.id = intervention_targets.intervention_id
                WHERE interventions.state != 'rejected'
                -- scope real
                AND interventions.nature = 'record'
                AND interventions.stopped_at <= '#{Time.zone.now}'
                AND EXTRACT(YEAR FROM interventions.started_at) = #{campaign.harvest_year}
              ) interventions
              GROUP BY activity_id
            ) interventions_support ON interventions_support.activity_id = activities.id
          SQL
        ).joins(
          <<~SQL
            LEFT JOIN (
              SELECT interventions.activity_id AS activity_id,
                     SUM(interventions.working_duration) AS working_duration
              FROM (
                SELECT DISTINCT
                  interventions.id AS id,
                  interventions.working_duration AS working_duration,
                  activity_productions.activity_id AS activity_id
                FROM interventions
                INNER JOIN intervention_parameters AS intervention_targets
                  ON intervention_targets.intervention_id = interventions.id
                  AND intervention_targets.type = 'InterventionTarget'
                INNER JOIN products
                  ON products.id = intervention_targets.product_id
                INNER JOIN activity_productions
                  ON activity_productions.id = products.activity_production_id
                INNER JOIN campaigns_interventions
                  ON interventions.id = campaigns_interventions.intervention_id
                WHERE campaigns_interventions.campaign_id = #{campaign.id}
                AND interventions.state != 'rejected'
                -- scope real
                AND interventions.nature = 'record'
                AND interventions.stopped_at <= '#{Time.zone.now}'
              ) interventions
              GROUP BY activity_id
            ) interventions ON interventions.activity_id = activities.id
          SQL
        ).select(
          <<~SQL
            activities.*,
            CASE WHEN interventions.working_duration IS NULL THEN
              COALESCE(interventions_support.working_duration, 0)
            ELSE
              interventions.working_duration
            END AS working_duration
          SQL
        )
      }

      scope :left_join_production_costs_of_campaign, lambda { |campaign|
        joins(
          <<~SQL
            LEFT JOIN (
              SELECT
                interventions.activity_id AS activity_id,
                SUM(interventions.total_costs) AS total_costs
              FROM (
                SELECT DISTINCT
                  interventions.id AS id,
                  SUM((intervention_costings.inputs_cost + intervention_costings.doers_cost + intervention_costings.tools_cost + intervention_costings.receptions_cost) * intervention_targets.imputation_ratio) AS total_costs,
                  activity_productions.activity_id AS activity_id
                FROM interventions
                INNER JOIN intervention_parameters AS intervention_targets
                  ON intervention_targets.intervention_id = interventions.id
                  AND intervention_targets.type = 'InterventionTarget'
                INNER JOIN products
                  ON products.id = intervention_targets.product_id
                INNER JOIN activity_productions
                  ON activity_productions.id = products.activity_production_id
                INNER JOIN campaigns_interventions
                  ON interventions.id = campaigns_interventions.intervention_id
                INNER JOIN intervention_costings ON interventions.costing_id = intervention_costings.id
                WHERE campaigns_interventions.campaign_id = #{campaign.id}
                AND interventions.state != 'rejected'
                -- scope real
                AND interventions.nature = 'record'
                AND interventions.stopped_at <= '#{Time.zone.now}'
                GROUP BY interventions.id, activity_productions.activity_id
              ) interventions
              GROUP BY activity_id
            ) activity_productions ON activity_productions.activity_id = activities.id
          SQL
        ).select(
          <<~SQL
            activities.*,
            COALESCE(activity_productions.total_costs, 0) AS total_costs
          SQL
        )
      }
    end
  end
end
