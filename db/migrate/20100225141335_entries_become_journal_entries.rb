class EntriesBecomeJournalEntries < ActiveRecord::Migration
  def self.up
    rename_table :entries, quote_table_name(:journal_entries)
    add_column :journal_entries, :journal_id, :integer
    if adapter_name == "PostgreSQL"
      execute "UPDATE #{quote_table_name(:journal_entries)} SET journal_id=journal_records.journal_id FROM #{quote_table_name(:journal_records)} AS journal_records WHERE record_id=journal_records.id"
    else
      for record in connection.select_all("SELECT id, journal_id FROM #{quote_table_name(:journal_records)}")
        execute "UPDATE #{quote_table_name(:journal_entries)} SET journal_id=#{record['journal_id']} WHERE record_id=#{record['id']}"
      end
    end
  end

  def self.down
    remove_column :journal_entries, :journal_id
    rename_table :journal_entries, quote_table_name(:entries)
  end
end
