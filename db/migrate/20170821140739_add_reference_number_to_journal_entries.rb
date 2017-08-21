class AddReferenceNumberToJournalEntries < ActiveRecord::Migration
  def change
    add_column :journal_entries, :reference_number, :string
  end
end
