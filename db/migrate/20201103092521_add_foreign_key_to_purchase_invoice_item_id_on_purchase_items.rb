class AddForeignKeyToPurchaseInvoiceItemIdOnPurchaseItems < ActiveRecord::Migration[4.2]
  def change
    reversible do |change|
      change.up do
        execute <<~SQL
          UPDATE parcel_items
          SET purchase_invoice_item_id = NULL
          WHERE purchase_invoice_item_id NOT IN (SELECT id FROM purchase_items)
        SQL
      end
    end

    add_foreign_key :parcel_items, :purchase_items, column: :purchase_invoice_item_id
  end
end
