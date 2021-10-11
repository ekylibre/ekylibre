class AddCampaignOnActivityTactic < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_tactics, :campaign_id, :integer, index: true
    add_foreign_key :activity_tactics, :campaigns, column: :campaign_id
  end
end
