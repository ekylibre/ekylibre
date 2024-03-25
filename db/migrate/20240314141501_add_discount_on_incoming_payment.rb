class AddDiscountOnIncomingPayment < ActiveRecord::Migration[5.2]
  def change
    add_column :incoming_payments, :with_discount, :boolean, null: false, default: false
    add_column :incoming_payments, :discount_amount, :decimal, precision: 19, scale: 4
    add_reference :incoming_payments, :discount_vat, index: true
    add_column :outgoing_payments, :with_discount, :boolean, null: false, default: false
    add_column :outgoing_payments, :discount_amount, :decimal, precision: 19, scale: 4
    add_reference :outgoing_payments, :discount_vat, index: true
  end
end


