class CreateSupplierPaymentMode < ActiveRecord::Migration[4.2]
  def change
    add_reference :entities, :supplier_payment_mode, index: true
  end
end
