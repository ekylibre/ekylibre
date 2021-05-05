class AddCampaignRefToCviStatements < ActiveRecord::Migration
  def change
    add_reference :cvi_statements, :campaign, index: true, foreign_key: true
  end
end
