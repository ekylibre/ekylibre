class AddIndexesToImproveBookkeep < ActiveRecord::Migration
  def change
    add_index :sales, :number
    add_index :journal_entry_items, :printed_on
  end
end
