class AddCampaignRefToCviStatements < ActiveRecord::Migration[4.2]
  def change
    add_reference :cvi_statements, :campaign, index: true, foreign_key: true
  end
end
