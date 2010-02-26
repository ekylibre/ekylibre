class EntriesBecomeJournalEntries < ActiveRecord::Migration
  def self.up
    rename_table :entries, :journal_entries
    add_column :journal_entries, :journal_id, :integer
    if adapter_name == "PostgreSQL"
      execute "UPDATE journal_entries SET journal_id=journal_records.journal_id FROM journal_records WHERE record_id=journal_records.id"
    else
      for record in select_all("SELECT id, journal_id FROM journal_records")
        execute "UPDATE journal_entries SET journal_id=#{record['journal_id']} WHERE record_id=#{record['id']}"
      end
    end
  end

  def self.down
    remove_column :journal_entries, :journal_id
    rename_table :journal_entries, :entries
  end
end
