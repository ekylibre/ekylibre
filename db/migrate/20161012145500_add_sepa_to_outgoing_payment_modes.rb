class AddSepaToOutgoingPaymentModes < ActiveRecord::Migration
  def change
    add_column :outgoing_payment_modes, :sepa, :boolean, null: false, default: false
  end
end
