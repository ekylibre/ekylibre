class ImplementSingleTableInheritanceToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :type, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE purchases SET type = 'PurchaseOrder' WHERE state IN ('draft','aborted','order','refused', 'estimate')"
        execute "UPDATE purchases SET type = 'PurchaseInvoice' WHERE state = 'invoice'"
      end
      dir.down do
        execute 'UPDATE purchases SET type = NULL '
      end
    end
  end
end
