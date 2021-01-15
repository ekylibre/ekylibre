class CreateExpirationPaymentDelayOnSupplier < ActiveRecord::Migration[4.2]
  def change
    change_table :entities do |t|
      t.string :supplier_payment_delay
    end
    change_table :purchases do |t|
      t.string :payment_delay
      t.datetime :payment_at
    end
  end
end
