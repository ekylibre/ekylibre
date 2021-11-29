class CreateEconomicIndicators < ActiveRecord::Migration[5.0]
  def change
    add_column :worker_contracts, :custom_fields, :jsonb
    add_column :activity_budget_items, :nature, :string
    add_column :activity_budget_items, :origin, :string

    create_view :economic_indicators, materialized: true

    add_index :economic_indicators, :activity_id
    add_index :economic_indicators, :campaign_id
  end
end
