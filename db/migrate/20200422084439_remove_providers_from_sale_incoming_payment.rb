class RemoveProvidersFromSaleIncomingPayment < ActiveRecord::Migration
  def change
    remove_column :incoming_payments, :providers
    remove_column :sales, :providers
  end
end
