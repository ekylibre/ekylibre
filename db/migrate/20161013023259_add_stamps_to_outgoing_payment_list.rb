class AddStampsToOutgoingPaymentList < ActiveRecord::Migration
  def change
    change_table :outgoing_payment_lists do |t|
      t.references(:creator, index: true)
      t.references(:updater, index: true)
      t.integer(:lock_version, null: false, default: 0)
    end

    change_column_null(:outgoing_payment_lists, :created_at, null: false)
    change_column_null(:outgoing_payment_lists, :updated_at, null: false)
  end
end
