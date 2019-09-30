class AddAttributesForIncomingPaymentExchange < ActiveRecord::Migration[4.2]
  def change
    add_column :incoming_payments, :codes, :jsonb
  end
end
