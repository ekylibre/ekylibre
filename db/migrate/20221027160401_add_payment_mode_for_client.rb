class AddPaymentModeForClient < ActiveRecord::Migration[5.1]
  def change
    add_column :entities, :client_payment_delay, :string
    add_reference :entities, :client_payment_mode, index: true, foreign_key: { to_table: :incoming_payment_modes}
  end
end
