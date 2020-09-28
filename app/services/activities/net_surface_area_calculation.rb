# frozen_string_literal: true

# Compute sum of support_shape of all the activty_productions linked to an activity
module Activities
  class NetSurfaceAreaCalculation

    SELECT_SRID = %{
      SELECT CASE
        WHEN string_value = 'WGS84' THEN 4326
        WHEN string_value = 'RGF93' THEN 2154
        WHEN string_value ~ '_' THEN SPLIT_PART(string_value, '_', 2)::INTEGER
        ELSE 0
      END AS srid
      FROM preferences WHERE name = 'map_measure_srs' LIMIT 1
    }

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
            ST_Area(ST_Transform(activity_productions.support_shape, (
            #{SELECT_SRID}
            )))/10000 as ha
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
