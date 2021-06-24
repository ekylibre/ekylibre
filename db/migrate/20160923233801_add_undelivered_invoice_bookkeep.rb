class AddUndeliveredInvoiceBookkeep < ActiveRecord::Migration[4.2]
  def change
    add_reference :purchases, :undelivered_invoice_entry, index: true
    add_reference :sales, :undelivered_invoice_entry, index: true
    add_reference :parcels, :undelivered_invoice_entry, index: true
  end
end
