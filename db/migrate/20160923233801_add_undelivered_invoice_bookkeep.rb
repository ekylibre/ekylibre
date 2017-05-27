class AddUndeliveredInvoiceBookkeep < ActiveRecord::Migration
  def change
    add_reference :purchases, :undelivered_invoice_entry, index: true
    add_reference :sales, :undelivered_invoice_entry, index: true
    add_reference :parcels, :undelivered_invoice_entry, index: true
  end
end
