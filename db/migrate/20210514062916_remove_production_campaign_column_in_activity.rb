class RemoveProductionCampaignColumnInActivity < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE activities
          SET production_started_on_year = CASE
                                             WHEN production_campaign = 'at_cycle_start' THEN 0
                                             ELSE -1
                                           END,
              production_stopped_on_year = 0
          WHERE production_campaign IS NOT NULL
        SQL

        remove_column :activities, :production_campaign
      end

      dir.down do
        add_column :activities, :production_campaign, :string

        execute <<~SQL
          UPDATE activities
          SET production_campaign = CASE
                                      WHEN production_started_on_year = 0 THEN 'at_cycle_start'
                                      ELSE 'at_cycle_end'
                                    END
          WHERE production_started_on_year IS NOT NULL
        SQL
      end
    end
  end
end
