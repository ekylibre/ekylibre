# frozen_string_literal: true

# Compute sum of support_shape of all the activty_productions linked to an activity
module Activities
  class NetSurfaceAreaCalculation

    def compute_net_surface_area(activity, campaign)
      activity_campaign_net_surface_area = ActiveRecord::Base.connection.execute <<~SQL
        SELECT
          activity_id,
          campaign_id,
          SUM(ha) AS net_surface_area
        FROM (
          SELECT DISTINCT
            activity_productions.id,
            activity_productions.activity_id AS activity_id,
            activity_productions_campaigns.campaign_id AS campaign_id,
            ST_Area(activity_productions.support_shape, TRUE) / 10000 AS ha
          FROM "activity_productions"
          INNER JOIN activity_productions_campaigns
            ON activity_productions_campaigns.activity_production_id = activity_productions.id
        ) subquery
        WHERE activity_id = #{activity.id}
        AND campaign_id = #{campaign.id}
        GROUP BY activity_id, campaign_id;
      SQL

      return 0.0.in(:hectare) if activity_campaign_net_surface_area.values.empty?

      activity_campaign_net_surface_area.first['net_surface_area'].to_d.in(:hectare)
    end
  end
end
