class CampaignsInterventionsViewForPerennials < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE VIEW campaigns_interventions AS
          SELECT DISTINCT c.id AS campaign_id,
                          i.id AS intervention_id
          FROM interventions i
          JOIN intervention_parameters ip ON ip.intervention_id = i.id
          JOIN products p ON p.id = ip.product_id
          JOIN activity_productions ap ON ap.id = p.activity_production_id
          JOIN activities a ON a.id = ap.activity_id
          JOIN campaigns c ON c.id = ap.campaign_id
            OR (a.production_cycle::text = 'perennial'::text
                AND i.started_at >= ap.started_on
                AND i.started_at > COALESCE(
                                      make_date(c.harvest_year + a.production_stopped_on_year - 1,
                                                date_part('month'::text, a.production_stopped_on)::integer,
                                                date_part('day'::text, a.production_stopped_on)::integer),
                                      make_date(c.harvest_year - 1 , 12, 31)
                                    )
                AND i.started_at <= COALESCE(
                                      make_date(c.harvest_year + a.production_stopped_on_year,
                                                date_part('month'::text, a.production_stopped_on)::integer,
                                                date_part('day'::text, a.production_stopped_on)::integer),
                                      make_date(c.harvest_year, 12, 31)
                                    )
                )
                AND i.started_at <= ap.stopped_on
          ORDER BY c.id;
        SQL
      end

      dir.down do
        execute <<~SQL
          CREATE OR REPLACE VIEW campaigns_interventions AS
          SELECT DISTINCT c.id AS campaign_id,
                          i.id AS intervention_id
          FROM interventions i
          JOIN intervention_parameters ip ON ip.intervention_id = i.id
          JOIN products p ON p.id = ip.product_id
          JOIN activity_productions ap ON ap.id = p.activity_production_id
          JOIN activities a ON a.id = ap.activity_id
          JOIN campaigns c ON c.id = ap.campaign_id
                              OR (a.production_cycle::text = 'perennial'::text
                                  AND i.started_at >= ap.started_on
                                  AND date_part('year'::text, i.started_at) = c.harvest_year::double precision)
          ORDER BY c.id;
        SQL
      end
    end
  end
end


