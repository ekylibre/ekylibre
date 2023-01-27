class RemoveNullConstraintOnCcpPlantingCampaign < ActiveRecord::Migration[4.2]
  def change
    change_column_null :cvi_cadastral_plants, :planting_campaign, true
  end
end
