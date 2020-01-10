class AddContinuousNumberAndValidatedAtToJournalEntries < ActiveRecord::Migration
  def change
    add_column :journal_entries, :continuous_number, :integer
    add_index :journal_entries, :continuous_number, unique: true
    add_column :journal_entries, :validated_at, :datetime
    reversible do |d|
      d.up do
        execute <<-SQL
          CREATE FUNCTION compute_journal_entry_continuous_number() RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
            BEGIN
              NEW.continuous_number := (SELECT (COALESCE(MAX(continuous_number),0)+1) FROM journal_entries);
              RETURN NEW;
            END
            $$;

          CREATE TRIGGER compute_journal_entries_continuous_number_on_update
          BEFORE UPDATE ON journal_entries
          FOR EACH ROW
          WHEN ((OLD.state <> NEW.state) AND (OLD.state = 'draft'))
          EXECUTE PROCEDURE compute_journal_entry_continuous_number();

          CREATE TRIGGER compute_journal_entries_continuous_number_on_insert
          BEFORE INSERT ON journal_entries
          FOR EACH ROW
          WHEN (NEW.state <> 'draft')
          EXECUTE PROCEDURE compute_journal_entry_continuous_number();
        SQL
      end
      d.down do
        execute <<-SQL
          DROP TRIGGER compute_journal_entries_continuous_number_on_update ON journal_entries;
          DROP TRIGGER compute_journal_entries_continuous_number_on_insert ON journal_entries;
          DROP FUNCTION compute_journal_entry_continuous_number();
        SQL
      end
    end
  end
end
