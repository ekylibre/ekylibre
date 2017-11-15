class AddRoleToPurchaseItem < ActiveRecord::Migration
  def change
    add_column :purchase_items, :role, :string
  end
end
