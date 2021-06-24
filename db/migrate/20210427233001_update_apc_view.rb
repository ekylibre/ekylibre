class UpdateApcView < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW activity_productions_campaigns AS
      SELECT DISTINCT c.id AS campaign_id,
         ap.id AS activity_production_id
         FROM activity_productions ap
         JOIN activities a ON ap.activity_id = a.id
         JOIN campaigns c ON c.id = ap.campaign_id
         WHERE a.production_cycle::text = 'annual'::text
       UNION
       SELECT DISTINCT c.id AS campaign_id,
        ap.id AS activity_production_id
        FROM activity_productions ap
        JOIN campaigns c ON (date_part('year'::text, ap.started_on) <= c.harvest_year::double precision AND c.harvest_year::double precision < date_part('year'::text, ap.stopped_on)
        OR date_part('year'::text, ap.started_on) < c.harvest_year::double precision AND c.harvest_year::double precision <= date_part('year'::text, ap.stopped_on))
        JOIN activities a ON ap.activity_id = a.id
        WHERE a.production_cycle::text = 'perennial'::text
        AND ap.stopped_on IS NOT NULL
        AND ap.started_on IS NOT NULL
      ORDER BY campaign_id, activity_production_id;
    SQL
  end

  def down
    execute <<-SQL
      CREATE OR REPLACE VIEW activity_productions_campaigns AS
      SELECT DISTINCT c.id as campaign_id, ap.id as activity_production_id
      FROM activity_productions ap
      INNER JOIN activities a ON ap.activity_id = a.id
      LEFT JOIN campaigns c ON (
        c.id = ap.campaign_id
        OR
        (
          c.id IS NOT NULL
          AND a.production_cycle = \'perennial\'
          AND (
            (
              a.production_campaign = \'at_cycle_start\'
              AND (
                (ap.stopped_on is null AND c.harvest_year >= EXTRACT(YEAR FROM ap.started_on))
                OR (ap.stopped_on is not null
                  AND EXTRACT(YEAR FROM ap.started_on) <= c.harvest_year
                  AND c.harvest_year < EXTRACT(YEAR FROM ap.stopped_on)
                )
              )
            )
            OR
            (
              a.production_campaign = \'at_cycle_end\'
              AND (
                (ap.stopped_on is null AND c.harvest_year > EXTRACT(YEAR FROM ap.started_on))
                OR (ap.stopped_on is not null
                  AND EXTRACT(YEAR FROM ap.started_on) < c.harvest_year
                  AND c.harvest_year <= EXTRACT(YEAR FROM ap.stopped_on)
                )
              )
            )
          )
        )
      )
      ORDER BY c.id;
    SQL
  end
end
