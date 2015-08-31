class ReplicateOnSaleAndPurchaseItems < ActiveRecord::Migration
  def change
    # add column to replicate information betwen sale and sale_item for better performance
    add_column :sale_items, :invoiced_at, :datetime
    add_column :sale_items, :accounted_at, :datetime
    add_column :sale_items, :payment_at, :datetime
    # add column to replicate information betwen purchase and purchase_item for better performance
    add_column :purchase_items, :invoiced_at, :datetime
    add_column :purchase_items, :accounted_at, :datetime

    # add values in tables
    execute "UPDATE sale_items SET invoiced_at=(SELECT invoiced_at FROM sales  WHERE sales.id = sale_items.sale_id)"
    execute "UPDATE sale_items SET accounted_at=(SELECT accounted_at FROM sales WHERE sales.id = sale_items.sale_id)"
    execute "UPDATE sale_items SET payment_at=(SELECT payment_at FROM sales  WHERE sales.id = sale_items.sale_id)"
    execute "UPDATE purchase_items SET invoiced_at=(SELECT invoiced_at FROM purchases WHERE purchases.id = purchase_items.purchase_id)"
    execute "UPDATE purchase_items SET accounted_at=(SELECT accounted_at FROM purchases WHERE purchases.id = purchase_items.purchase_id)"


  end
end
