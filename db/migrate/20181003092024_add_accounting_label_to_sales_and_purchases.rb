class AddAccountingLabelToSalesAndPurchases < ActiveRecord::Migration
  def change
    add_column :sale_items, :accounting_label, :string
    add_column :purchase_items, :accounting_label, :string
    add_column :journal_entry_items, :accounting_label, :string
  end
end
