class AddTotalCostsInActivityProductions < ActiveRecord::Migration
  def change
    add_column :activity_productions, :total_tool_cost, :decimal, precision: 19, scale: 4
    add_column :activity_productions, :total_input_cost, :decimal, precision: 19, scale: 4
    add_column :activity_productions, :total_doer_cost, :decimal, precision: 19, scale: 4
  end
end
