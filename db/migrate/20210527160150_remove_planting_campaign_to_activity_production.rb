class RemovePlantingCampaignToActivityProduction < ActiveRecord::Migration[5.0]
  def change
    remove_reference :activity_productions, :planting_campaign, index: true
  end
end
