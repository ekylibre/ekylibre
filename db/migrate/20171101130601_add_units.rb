class AddUnits < ActiveRecord::Migration[4.2]
  def change
    add_column :sale_contract_items, :quantity_unit, :string
    add_column :project_tasks, :forecast_duration_unit, :string
  end
end
