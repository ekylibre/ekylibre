class AddGapOnStockBookkeep < ActiveRecord::Migration[4.2]
  def change
    add_reference :purchases, :quantity_gap_on_invoice_entry, index: true
    add_reference :sales, :quantity_gap_on_invoice_entry, index: true
  end
end
