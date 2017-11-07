class AddActivityProductionToProduct < ActiveRecord::Migration
  def change
    add_reference :products, :activity_production, index: true, foreign_key: true

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          UPDATE products AS p
          SET activity_production_id = td.activity_production_id
          FROM target_distributions AS td
          WHERE p.id = td.target_id
            AND td.stopped_at IS NULL
        SQL

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW activities_interventions AS
           SELECT DISTINCT interventions.id AS intervention_id,
              activities.id AS activity_id
             FROM activities
               JOIN activity_productions ON (activity_productions.activity_id = activities.id)
               JOIN products ON (products.activity_production_id = activity_productions.id)
               JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
               JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
            ORDER BY interventions.id;
        SQL

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW activity_productions_interventions AS
           SELECT DISTINCT interventions.id AS intervention_id,
              products.activity_production_id
             FROM activity_productions
               JOIN products ON (products.activity_production_id = activity_productions.id)
               JOIN intervention_parameters ON (products.id = intervention_parameters.product_id)
               JOIN interventions ON (intervention_parameters.intervention_id = interventions.id)
            ORDER BY interventions.id;
        SQL

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW campaigns_interventions AS
           SELECT DISTINCT campaigns.id AS campaign_id,
              interventions.id AS intervention_id
             FROM interventions
               JOIN intervention_parameters ON (intervention_parameters.intervention_id = interventions.id)
               JOIN products ON (products.id = intervention_parameters.product_id)
               JOIN activity_productions ON (products.activity_production_id = activity_productions.id)
               JOIN campaigns ON (activity_productions.campaign_id = campaigns.id)
            ORDER BY campaigns.id;
        SQL
      end

      dir.down do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW activities_interventions AS
           SELECT DISTINCT interventions.id AS intervention_id,
              activities.id AS activity_id
             FROM ((((activities
               JOIN activity_productions ON ((activity_productions.activity_id = activities.id)))
               JOIN target_distributions ON ((target_distributions.activity_production_id = activity_productions.id)))
               JOIN intervention_parameters ON ((target_distributions.target_id = intervention_parameters.product_id)))
               JOIN interventions ON ((intervention_parameters.intervention_id = interventions.id)))
            ORDER BY interventions.id;
        SQL

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW activity_productions_interventions AS
           SELECT DISTINCT interventions.id AS intervention_id,
              target_distributions.activity_production_id
             FROM (((activities
               JOIN target_distributions ON ((target_distributions.activity_id = activities.id)))
               JOIN intervention_parameters ON ((target_distributions.target_id = intervention_parameters.product_id)))
               JOIN interventions ON ((intervention_parameters.intervention_id = interventions.id)))
            ORDER BY interventions.id;
        SQL

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW campaigns_interventions AS
           SELECT DISTINCT campaigns.id AS campaign_id,
              interventions.id AS intervention_id
             FROM ((((interventions
               JOIN intervention_parameters ON ((intervention_parameters.intervention_id = interventions.id)))
               JOIN target_distributions ON ((target_distributions.target_id = intervention_parameters.product_id)))
               JOIN activity_productions ON ((target_distributions.activity_production_id = activity_productions.id)))
               JOIN campaigns ON ((activity_productions.campaign_id = campaigns.id)))
            ORDER BY campaigns.id;
        SQL
      end
    end
  end
end
