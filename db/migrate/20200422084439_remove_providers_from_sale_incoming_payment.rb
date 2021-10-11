class RemoveProvidersFromSaleIncomingPayment < ActiveRecord::Migration[4.2]
  def change
    remove_column :incoming_payments, :providers
    remove_column :sales, :providers
  end
end
