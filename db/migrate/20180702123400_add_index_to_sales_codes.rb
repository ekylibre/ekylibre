class AddIndexToSalesCodes < ActiveRecord::Migration[4.2]
  def change
    add_index :sales, :codes
    add_index :journal_entries, :printed_on
    add_index :journal_entry_items, :entry_number
  end
end
