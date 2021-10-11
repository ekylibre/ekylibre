class AddNatureOnBudget < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_budgets, :nature, :string, index: true
    add_column :activity_budgets, :technical_itinerary_id, :integer, index: true
    add_column :activity_budget_items, :used_on, :date
    add_column :activity_budget_items, :paid_on, :date
  end
end
