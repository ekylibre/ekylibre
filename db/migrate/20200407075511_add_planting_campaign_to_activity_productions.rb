class AddPlantingCampaignToActivityProductions < ActiveRecord::Migration[4.2]
  def change
    add_reference :activity_productions, :planting_campaign, index: true
  end
end
