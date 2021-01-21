class AddAccountingLabelToSalesAndPurchases < ActiveRecord::Migration[4.2]
  def change
    add_column :sale_items, :accounting_label, :string
    add_column :purchase_items, :accounting_label, :string
    add_column :journal_entry_items, :accounting_label, :string
  end
end
