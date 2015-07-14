class SimplifySalesAndPurchasesComputation < ActiveRecord::Migration
  def change
    revert do
      change_column_null :taxes, :computation_method, false
    end

    reversible do |dir|
      dir.down do
        execute "UPDATE taxes SET computation_method = 'amount'"
      end
    end

    # Removes unused columns of taxes
    revert do
      add_column :taxes, :computation_method, :string
      add_column :taxes, :included,           :boolean, null: false, default: false
      add_column :taxes, :reductible,         :boolean, null: false, default: true
    end

    # Removes complex columns of sales
    add_column :sale_items, :credited_quantity, :decimal, precision: 19, scale: 4
    reversible do |dir|
      dir.up do
        execute "UPDATE sale_items SET credited_quantity = -quantity WHERE type = 'SaleCreditItem'"
        # execute "UPDATE sale_items SET unit_amount = amount/quantity, unit_pretax_amount = pretax_amount/quantity"
      end
      dir.down do
        execute "UPDATE sales SET type = CASE WHEN credit THEN 'SaleCredit' ELSE 'Sale' END, computation_method = 'tax_quantity'"
        execute "UPDATE sale_items SET reference_value = 'pretax_amount'"
        execute "UPDATE sale_items SET type = 'SaleCreditItem' WHERE sale_id IN (SELECT id FROM sales WHERE type = 'SaleCredit')"
      end
    end
    remove_column :sale_items, :type, :string
    remove_column :sale_items, :reference_value, :string
    remove_column :sales, :type, :string
    remove_column :sales, :computation_method, :string

    # Removes complex columns of purchases
    reversible do |dir|
      dir.up do
        # execute "UPDATE purchase_items SET unit_amount = amount/quantity, unit_pretax_amount = pretax_amount/quantity"
      end
      dir.down do
        execute "UPDATE purchases SET computation_method = 'tax_quantity'"
        execute "UPDATE purchase_items SET reference_value = 'pretax_amount'"
      end
    end
    remove_column :purchase_items, :reference_value, :string
    remove_column :purchases, :computation_method, :string
  end
end
