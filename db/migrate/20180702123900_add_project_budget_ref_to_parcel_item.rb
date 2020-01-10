class AddProjectBudgetRefToParcelItem < ActiveRecord::Migration
  def change
    add_reference :parcel_items, :project_budget, index: true, foreign_key: true
  end
end
