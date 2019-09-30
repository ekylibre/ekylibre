class SetPurchaseItemVariantToNullable < ActiveRecord::Migration[4.2]
  def change
    change_column :purchase_items, :variant_id, :integer, null: true
  end
end
