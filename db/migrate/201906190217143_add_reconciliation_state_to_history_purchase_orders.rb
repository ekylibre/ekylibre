class AddReconciliationStateToHistoryPurchaseOrders < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE purchases
         SET reconciliation_state = 'to_reconcile'
       WHERE reconciliation_state IS NULL
         AND type = 'PurchaseOrder'
    SQL
  end

  def down
    # NOOP
  end
end
