class AddTotalCostsInInterventions < ActiveRecord::Migration
  def change
    add_column :interventions, :total_tool_cost, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :interventions, :total_input_cost, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :interventions, :total_time_cost, :decimal, precision: 19, scale: 4, null: false, default: 0.0
  end
end
