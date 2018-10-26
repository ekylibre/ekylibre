class AddPurchaseInvoiceItemsToParcels < ActiveRecord::Migration
  def change
    add_column :parcel_items, :purchase_order_item_id, :integer, index: true
    add_foreign_key :parcel_items, :purchase_items, column: :purchase_order_item_id

    rename_column :parcel_items, :purchase_item_id, :purchase_invoice_item_id
  end
end
