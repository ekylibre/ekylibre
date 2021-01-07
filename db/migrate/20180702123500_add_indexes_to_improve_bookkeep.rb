class AddIndexesToImproveBookkeep < ActiveRecord::Migration[4.2]
  def change
    add_index :sales, :number
    add_index :journal_entry_items, :printed_on
  end
end
