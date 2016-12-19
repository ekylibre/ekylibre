class AddPositionToOutgoingPayment < ActiveRecord::Migration
  def change
    add_column :outgoing_payments, :position, :integer
  end
end
