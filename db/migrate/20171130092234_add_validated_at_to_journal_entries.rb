class AddValidatedAtToJournalEntries < ActiveRecord::Migration
  def change
    add_column :journal_entries, :validated_at, :datetime
  end
end
