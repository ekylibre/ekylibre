class AddReconciliationStateToReception < ActiveRecord::Migration[4.2]
  def change
    add_column :parcels, :reconciliation_state, :string
  end
end
