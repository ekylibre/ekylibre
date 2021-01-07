class AddRoleToPurchaseItem < ActiveRecord::Migration[4.2]
  def change
    add_column :purchase_items, :role, :string
  end
end
