class AddIsacomptaLetterToJournalEntryItem < ActiveRecord::Migration[5.0]
  def change
    add_column :journal_entry_items, :isacompta_letter, :string, limit: 4
  end
end
