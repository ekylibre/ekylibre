class AddIdPurchaseOrderToClose < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :purchase_order_to_close_id, :integer, index: true
    add_foreign_key :parcel_items, :purchases, column: :purchase_order_to_close_id
  end
end
