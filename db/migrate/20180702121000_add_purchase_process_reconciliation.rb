class AddPurchaseProcessReconciliation < ActiveRecord::Migration
  def change
    unless column_exists? :purchases, :reconciliation_state
      add_column :purchases, :reconciliation_state, :string
    end
  end
end
