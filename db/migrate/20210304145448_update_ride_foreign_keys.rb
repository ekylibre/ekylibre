class UpdateRideForeignKeys < ActiveRecord::Migration[5.0]
  def up
    remove_foreign_key :crumbs, :rides
    add_foreign_key :crumbs, :rides, on_update: :cascade, on_delete: :cascade

    remove_foreign_key :rides, :ride_sets
    add_foreign_key :rides, :ride_sets, on_update: :cascade, on_delete: :cascade

    remove_foreign_key :rides, :products
    add_foreign_key :rides, :products, on_update: :cascade, on_delete: :cascade
  end

  def down
    remove_foreign_key :crumbs, :rides
    add_foreign_key :crumbs, :rides

    remove_foreign_key :rides, :ride_sets
    add_foreign_key :rides, :ride_sets

    remove_foreign_key :rides, :products
    add_foreign_key :rides, :products
  end
end
