class AddReconciliationStateToReception < ActiveRecord::Migration
  def change
    add_column :parcels, :reconciliation_state, :string
  end
end
