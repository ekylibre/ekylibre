class AttachProductionToCampaign < ActiveRecord::Migration
  def change
    add_column :activities, :production_cycle, :string
    add_column :activities, :target_campaign, :string
    add_reference :activity_productions, :campaign, index: true

    reversible do |q|
      q.up do

        # 730 => 2 years
        execute <<-SQL
          UPDATE activities
          SET production_cycle = CASE
          WHEN id IN
           (SELECT activity_id FROM activity_productions AS a WHERE a.stopped_on is null OR (a.stopped_on - a.started_on) > 730 )
          THEN 'perennial'
          ELSE 'annual'
          END
        SQL

        execute <<-SQL
          UPDATE activity_productions
          SET campaign_id = c.id
          FROM campaigns as c
          WHERE extract (year from activity_productions.stopped_on) = c.harvest_year
        SQL

        execute <<-SQL
          UPDATE activities
          SET production_cycle = 'perennial'
          WHERE id IN (SELECT activity_id FROM activity_productions AS ap JOIN activities AS a ON ap.activity_id = a.id WHERE ap.campaign_id is null
           AND a.production_cycle = 'annual')
        SQL

        # Set default value for perennial activities
        execute <<-SQL
          UPDATE activities
          SET target_campaign = 'next'
          WHERE activities.production_cycle = 'perennial'
        SQL

      end
    end

    change_column_null :activities, :production_cycle, false

    revert do
      add_column :campaigns, :name, :string
      add_column :campaigns, :number, :string
      add_column :campaigns, :started_on, :date
      add_column :campaigns, :stopped_on, :date
    end

    #TODO: Make reversible
  end
end
