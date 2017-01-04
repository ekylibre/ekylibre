class AddAttributesForIncomingPaymentExchange < ActiveRecord::Migration
  def change
    add_column :incoming_payments, :codes, :jsonb
  end
end
