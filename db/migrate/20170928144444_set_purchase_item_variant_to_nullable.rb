class SetPurchaseItemVariantToNullable < ActiveRecord::Migration
  def change
    change_column :purchase_items, :variant_id, :integer, null: true
  end
end
