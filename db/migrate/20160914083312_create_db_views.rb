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
      CREATE OR REPLACE VIEW activities_campaigns AS
        SELECT DISTINCT campaigns.id as campain_id, activities.id as activity_id
        FROM activities
        INNER JOIN activity_productions ON activity_productions.activity_id = activities.id
        INNER JOIN campaigns ON activity_productions.campaign_id = campaigns.id
        ORDER BY campaigns.id;
    '

    execute '
      CREATE OR REPLACE VIEW activity_productions_campaigns AS
        SELECT DISTINCT campaigns.id as campain_id, activity_productions.id as activity_production_id
        FROM activity_productions
        INNER JOIN campaigns ON activity_productions.campaign_id = campaigns.id
        ORDER BY campaigns.id;
    '

    execute '
      CREATE OR REPLACE VIEW campaigns_interventions AS
        SELECT DISTINCT campaigns.id as campain_id, interventions.id as intervention_id
        FROM activity_productions
        INNER JOIN target_distributions ON target_distributions.activity_production_id = activity_productions.id
        INNER JOIN intervention_parameters ON target_distributions.target_id = intervention_parameters.id
        INNER JOIN interventions ON intervention_parameters.intervention_id = interventions.id
        INNER JOIN campaigns ON activity_productions.campaign_id = campaigns.id
        ORDER BY campaigns.id;
    '
  end

  def down
    execute "
      DROP VIEW IF EXISTS activities_interventions;
      DROP VIEW IF EXISTS activity_productions_interventions;
      DROP VIEW IF EXISTS activities_campains;
      DROP VIEW IF EXISTS activity_productions_campaigns;
      DROP VIEW IF EXISTS campaigns_interventions;
    "
  end
end
