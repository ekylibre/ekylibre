class CreateSupplierPaymentMode < ActiveRecord::Migration
  def change
    add_reference :entities, :supplier_payment_mode, index: true
  end
end
