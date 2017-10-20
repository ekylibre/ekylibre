class AddPurchaseProcessReconciliation < ActiveRecord::Migration
  def change
    add_column :purchases, :reconciliation_state, :string
  end
end
