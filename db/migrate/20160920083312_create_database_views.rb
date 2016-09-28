class CreateDatabaseViews < ActiveRecord::Migration
  def up
    execute '
      CREATE VIEW activities_interventions AS
        SELECT DISTINCT interventions.id as intervention_id, activities.id as activity_id
        FROM activities
        INNER JOIN target_distributions ON target_distributions.activity_id = activities.id
        INNER JOIN intervention_parameters ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN interventions ON intervention_parameters.intervention_id = interventions.id
        ORDER BY interventions.id;
    '
    execute 'CREATE RULE delete_activities_interventions AS ON DELETE TO activities_interventions DO INSTEAD NOTHING'

    execute '
      CREATE VIEW activity_productions_interventions AS
        SELECT DISTINCT interventions.id as intervention_id, target_distributions.activity_production_id as activity_production_id
        FROM activities
        INNER JOIN target_distributions ON target_distributions.activity_id = activities.id
        INNER JOIN intervention_parameters ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN interventions ON intervention_parameters.intervention_id = interventions.id
        ORDER BY interventions.id;
    '
    execute 'CREATE RULE delete_activity_productions_interventions AS ON DELETE TO activity_productions_interventions DO INSTEAD NOTHING'

    execute '
      CREATE VIEW activity_productions_campaigns AS
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
    '
    execute 'CREATE RULE delete_activity_productions_campaigns AS ON DELETE TO activity_productions_campaigns DO INSTEAD NOTHING'

    execute '
      CREATE VIEW activities_campaigns AS
        SELECT DISTINCT c.id as campaign_id, a.id as activity_id
        FROM activities a
        LEFT JOIN campaigns c ON (
           (a.id, c.id) IN(
             SELECT ab.activity_id, ab.campaign_id FROM activity_budgets ab WHERE ab.campaign_id = c.id AND ab.activity_id = a.id
           )
           OR (a.id, c.id) IN(
             SELECT ap.activity_id, ap.campaign_id FROM activity_productions ap WHERE ap.campaign_id = c.id AND ap.activity_id = a.id
           )
        )
    '
    execute 'CREATE RULE delete_activities_campaigns AS ON DELETE TO activities_campaigns DO INSTEAD NOTHING'

    execute '
      CREATE VIEW campaigns_interventions AS
        SELECT DISTINCT campaigns.id as campaign_id, interventions.id as intervention_id
        FROM interventions
        INNER JOIN intervention_parameters ON intervention_parameters.intervention_id = interventions.id
        INNER JOIN target_distributions ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN activity_productions ON target_distributions.activity_production_id = activity_productions.id
        INNER JOIN campaigns ON activity_productions.campaign_id = campaigns.id
        ORDER BY campaigns.id;
    '
    execute 'CREATE RULE delete_campaigns_interventions AS ON DELETE TO campaigns_interventions DO INSTEAD NOTHING'
  end

  def down
    execute 'DROP VIEW activities_interventions'
    execute 'DROP VIEW activity_productions_interventions'
    execute 'DROP VIEW activity_productions_campaigns'
    execute 'DROP VIEW activities_campains'
    execute 'DROP VIEW campaigns_interventions'
  end
end
