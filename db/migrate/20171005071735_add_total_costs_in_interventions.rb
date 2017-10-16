class AddTotalCostsInInterventions < ActiveRecord::Migration
  def change
    add_column :interventions, :total_tool_cost, :decimal, precision: 19, scale: 4
    add_column :interventions, :total_input_cost, :decimal, precision: 19, scale: 4
    add_column :interventions, :total_doer_cost, :decimal, precision: 19, scale: 4
  end
end
