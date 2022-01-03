class AddColumnsToActivityBudgetItem < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_budget_items, :use_transfer_price, :boolean, default: false
    add_column :activity_budget_items, :transfer_price, :float
    add_column :activity_budget_items, :locked, :boolean, default: false
    add_reference :activity_budget_items, :transfered_activity_budget, foreign_key: { to_table: :activity_budgets}
  end
end
