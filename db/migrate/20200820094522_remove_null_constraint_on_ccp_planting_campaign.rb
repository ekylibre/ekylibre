class RemoveNullConstraintOnCcpPlantingCampaign < ActiveRecord::Migration
  def change
    change_column_null :cvi_cadastral_plants, :planting_campaign, true
  end
end
