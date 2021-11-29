class AddUnitIdOnBudgetItems < ActiveRecord::Migration[5.0]
  def change
    add_reference :activity_budget_items, :unit, index: true, foreign_key: { to_table: :units }
  end
end
