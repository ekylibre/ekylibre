class CreateIncomingHarvestIndicators < ActiveRecord::Migration[5.2]
  def change
    create_view :incoming_harvest_indicators, materialized: true
    add_index :incoming_harvest_indicators, :activity_id
    add_index :incoming_harvest_indicators, :campaign_id
    add_index :incoming_harvest_indicators, :activity_production_id
    add_index :incoming_harvest_indicators, :crop_id
  end
end
