class AddTotalCostInInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :total_cost, :decimal, precision: 19, scale: 4
  end
end
