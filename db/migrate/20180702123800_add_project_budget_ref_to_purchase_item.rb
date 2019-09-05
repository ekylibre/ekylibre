class AddProjectBudgetRefToPurchaseItem < ActiveRecord::Migration
  def change
    add_reference :purchase_items, :project_budget, index: true, foreign_key: true
  end
end
