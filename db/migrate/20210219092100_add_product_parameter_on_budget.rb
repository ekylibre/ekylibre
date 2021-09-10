class AddProductParameterOnBudget < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_budget_items, :product_parameter_id, :integer, index: true
    add_foreign_key :activity_budgets, :technical_itineraries, column: :technical_itinerary_id
    add_foreign_key :activity_budget_items, :intervention_template_product_parameters, column: :product_parameter_id
  end
end
