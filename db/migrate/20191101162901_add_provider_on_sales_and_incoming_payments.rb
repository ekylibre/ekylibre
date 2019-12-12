class AddProviderOnSalesAndIncomingPayments < ActiveRecord::Migration
  def up
    # add providers colums to store pairs on provider / id number on sale and incoming payment
    add_column :sales, :providers, :jsonb
    add_column :incoming_payments, :providers, :jsonb
  end

  def down
    remove_column :sales, :providers
    remove_column :incoming_payments, :providers
  end
end
