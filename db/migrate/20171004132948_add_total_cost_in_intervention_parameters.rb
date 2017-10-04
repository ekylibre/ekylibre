class AddTotalCostInInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :total_cost, :decimal, precision: 19, scale: 4, null: false, default: 0.0
  end
end
