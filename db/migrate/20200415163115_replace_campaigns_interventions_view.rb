class ReplaceCampaignsInterventionsView < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP VIEW IF EXISTS campaigns_interventions;

      CREATE OR REPLACE VIEW campaigns_interventions AS
        SELECT DISTINCT c.id AS campaign_id, i.id AS intervention_id
        FROM interventions AS i
        INNER JOIN intervention_parameters AS ip ON ip.intervention_id = i.id
        INNER JOIN products AS p ON p.id = ip.product_id
        INNER JOIN activity_productions AS ap ON ap.id = p.activity_production_id
        INNER JOIN activities AS a ON a.id = ap.activity_id
        INNER JOIN campaigns AS c ON c.id = ap.campaign_id
          OR a.production_cycle = 'perennial'
            AND i.started_at >= ap.started_on
            AND EXTRACT(YEAR FROM i.started_at) = c.harvest_year
        ORDER BY c.id;

      CREATE RULE delete_campaigns_interventions AS ON DELETE TO campaigns_interventions DO INSTEAD NOTHING
    SQL
  end
end
