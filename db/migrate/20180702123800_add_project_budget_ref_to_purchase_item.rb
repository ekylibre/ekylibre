class AddProjectBudgetRefToPurchaseItem < ActiveRecord::Migration[4.2]
  def change
    add_reference :purchase_items, :project_budget, index: true, foreign_key: true
  end
end
