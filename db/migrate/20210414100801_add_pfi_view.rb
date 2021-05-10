class AddPfiView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW pfi_campaigns_activities_interventions AS
      SELECT
        pip.campaign_id AS campaign_id,
        a.id AS activity_id,
        ap.id AS activity_production_id,
        p.id AS crop_id,
        pip.segment_code AS segment_code,
        SUM(pip.pfi_value) AS crop_pfi_value,
        ap.size_value AS activity_production_surface_area,
        p.initial_population AS crop_surface_area,
        ROUND(SUM(pip.pfi_value) * ROUND((COALESCE(p.initial_population, 0) / COALESCE(ap.size_value, 1)), 2), 2) AS activity_production_pfi_value,
        ROUND(SUM(pip.pfi_value) * (ap.size_value / (SELECT SUM(aps.size_value) FROM activity_productions aps WHERE aps.activity_id = a.id AND aps.id IN (SELECT activity_production_id FROM activity_productions_campaigns WHERE campaign_id = pip.campaign_id))), 2) AS activity_pfi_value
      FROM pfi_intervention_parameters AS pip
      INNER JOIN intervention_parameters AS ip ON pip.target_id = ip.id
      INNER JOIN products AS p ON ip.product_id = p.id
      INNER JOIN activity_productions AS ap ON p.activity_production_id = ap.id
      INNER JOIN activities AS a ON ap.activity_id = a.id
      WHERE pip.nature = 'crop'
      GROUP BY pip.campaign_id, a.id, ap.id, ap.size_value, p.id, pip.segment_code
      ORDER BY campaign_id, activity_id, activity_production_id, segment_code;

    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS pfi_campaigns_activities_interventions;
    SQL
  end

end
