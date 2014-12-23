class EnhanceInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :name, :string
    execute "UPDATE inventories SET name = 'Inventory #' || id"
    change_column_null :inventories, :name, false

    # add_column :inventories, :forbid_delta_reflection, :boolean, null: false, default: false
    remove_column :inventory_items, :product_reading_task_id

    add_column :inventories, :achieved_at, :datetime
    execute "UPDATE inventories SET achieved_at = reflected_at"

    rename_column :inventory_items, :theoric_population, :expected_population
    rename_column :inventory_items, :population, :actual_population

    add_column :inventory_items, :actual_shape, :geometry, srid: 4326
    add_column :inventory_items, :expected_shape, :geometry, srid: 4326
  end
end
