class CreateOutgoingPaymentList < ActiveRecord::Migration
  def change
    create_table :outgoing_payment_lists do |t|
      t.string :number

      t.timestamps null: false
    end

    change_table :outgoing_payments do |t|
      t.integer :list_id, index: true
    end
  end
end
