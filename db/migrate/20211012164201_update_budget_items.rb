class UpdateBudgetItems < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_budget_items, :repetition, :integer, null: false, default: 1
    add_column :activity_budget_items, :frequency, :string, null: false, default: 'per_year'
    add_column :activity_budget_items, :global_amount, :decimal, precision: 19, scale: 4
    add_column :technical_itinerary_intervention_templates, :repetition, :integer, null: false, default: 1
    add_column :technical_itinerary_intervention_templates, :frequency, :string, null: false, default: 'per_year'  
    update_view :economic_indicators, version: 2, revert_to_version: 1, materialized: true
  end
end
