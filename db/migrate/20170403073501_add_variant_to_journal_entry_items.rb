class AddVariantToJournalEntryItems < ActiveRecord::Migration
  def change
    add_column :journal_entry_items, :variant_id, :integer 
  end
end
