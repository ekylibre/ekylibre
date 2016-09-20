class CreateDbViews < ActiveRecord::Migration
  def up
    execute '
      CREATE OR REPLACE VIEW activities_interventions AS
        SELECT DISTINCT interventions.id as intervention_id, activities.id as activity_id
        FROM activities
        INNER JOIN target_distributions ON target_distributions.activity_id = activities.id
        INNER JOIN intervention_parameters ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN interventions ON intervention_parameters.intervention_id = interventions.id
        ORDER BY interventions.id;
    '

    execute '
      CREATE OR REPLACE VIEW activity_productions_interventions AS
        SELECT DISTINCT interventions.id as intervention_id, target_distributions.activity_production_id as activity_production_id
        FROM activities
        INNER JOIN target_distributions ON target_distributions.activity_id = activities.id
        INNER JOIN intervention_parameters ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN interventions ON intervention_parameters.intervention_id = interventions.id
        ORDER BY interventions.id;
    '

    execute '
      CREATE OR REPLACE VIEW activity_productions_campaigns AS
        SELECT DISTINCT c.id as campaign_id, ap.id as activity_production_id, a.id as activity_id
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

    execute '
      CREATE OR REPLACE VIEW activities_campaigns AS
        SELECT DISTINCT campaign_id, activity_id
        FROM activity_productions_campaigns;
    '

    execute '
      CREATE OR REPLACE VIEW campaigns_interventions AS
        SELECT DISTINCT campaigns.id as campaign_id, interventions.id as intervention_id
        FROM interventions
        INNER JOIN intervention_parameters ON intervention_parameters.intervention_id = interventions.id
        INNER JOIN target_distributions ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN activity_productions ON target_distributions.activity_production_id = activity_productions.id
        INNER JOIN campaigns ON activity_productions.campaign_id = campaigns.id
        ORDER BY campaigns.id;
    '
  end

  def down
    execute "
      DROP VIEW IF EXISTS activities_interventions;
      DROP VIEW IF EXISTS activity_productions_interventions;
      DROP VIEW IF EXISTS activity_productions_campaigns;
      DROP VIEW IF EXISTS activities_campains;
      DROP VIEW IF EXISTS campaigns_interventions;
    "
  end
end
