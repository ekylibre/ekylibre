class FixBudgetMainOutput < ActiveRecord::Migration[5.0]
  def up
    add_column :activity_budget_items, :main_output, :boolean, null: false, default: false
    update_view :economic_indicators, version: 3, materialized: true
    drop_table :activity_cost_outputs
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
