# frozen_string_literal: true

# Compute sum of working zone area of all the interventions linked to
# an activity
module Activities
  class WorkingZoneAreaCalculation
    PLANTING = Procedo::Procedure.of_category(:planting).map do |procedure|
      procedure.name.to_s.insert(0, "'").insert(-1, "'")
    end.join(', ')

    def compute_working_zone_area(activity, campaign)
      activity_campaign_working_zone_area = ActiveRecord::Base.connection.execute <<-SQL
        SELECT
          activity_id,
          campaign_id,
          SUM(area) AS working_zone_area
        FROM (
          SELECT DISTINCT
            interventions.id AS intervention_id,
            intervention_parameters.id,
            products.id,
            activity_productions.activity_id AS activity_id,
            activity_productions_campaigns.campaign_id AS campaign_id,
            campaigns_interventions.campaign_id AS campaigns_interventions_campaign_id,
            CASE
              WHEN interventions.procedure_name NOT IN (#{PLANTING})
              THEN ST_Area(intervention_parameters.working_zone, TRUE) / 10000
              /* if procedure is planting, it should take the initial shape of
                 the associated products                                    */
              ELSE ST_Area(products.initial_shape, TRUE) / 10000
            END AS area
          FROM interventions
          INNER JOIN campaigns_interventions ON campaigns_interventions.intervention_id = interventions.id
          INNER JOIN intervention_parameters
            ON interventions.id = intervention_parameters.intervention_id
            AND (CASE
              WHEN interventions.procedure_name IN (#{PLANTING}) THEN
                'InterventionOutput'
              ELSE 'InterventionTarget'
            END) = intervention_parameters.type
          INNER JOIN products
            ON products.id = intervention_parameters.product_id
          INNER JOIN activity_productions
            ON activity_productions.id = products.activity_production_id
          INNER JOIN activity_productions_campaigns
            ON activity_productions.id = activity_productions_campaigns.activity_production_id
          -- only with interventions with nature record and state is not rejected
          WHERE interventions.state != 'rejected'
          AND interventions.nature = 'record'
        ) subquery
        WHERE activity_id = #{activity.id}
        AND campaign_id = #{campaign.id}
        AND campaigns_interventions_campaign_id = #{campaign.id}
        GROUP BY activity_id, campaign_id, campaigns_interventions_campaign_id;
      SQL

      return 0.0.in(:hectare) if activity_campaign_working_zone_area.values.empty?

      activity_campaign_working_zone_area.first['working_zone_area'].to_d.in(:hectare)
    end
  end
end
