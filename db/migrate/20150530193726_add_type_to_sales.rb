class AddTypeToSales < ActiveRecord::Migration
  def up
    add_column :sales, :type, :string
    execute "UPDATE sales SET type = CASE WHEN credited_sale_id IN (SELECT id FROM sales) THEN 'SaleCredit' ELSE 'Sale' END"
    add_column :sale_items, :type, :string
    execute "UPDATE sale_items SET type = CASE WHEN sale_id IN (SELECT id FROM sales WHERE type = 'SaleCredit') THEN 'SaleCreditItem' ELSE 'SaleItem' END"
  end

  def down
    remove_column :sales, :type
    remove_column :sale_items, :type
  end
end
