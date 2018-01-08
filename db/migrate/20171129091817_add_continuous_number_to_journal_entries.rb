class AddContinuousNumberToJournalEntries < ActiveRecord::Migration
  def change
    add_column :journal_entries, :continuous_number, :integer
    reversible do |d|
      d.up do
        execute <<-SQL
          CREATE SEQUENCE journal_entries_continuous_number;

          CREATE FUNCTION compute_journal_entry_continuous_number() RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
            BEGIN
              NEW.continuous_number := NEXTVAL('journal_entries_continuous_number');
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
          WHEN (NEW.state <>'draft')
          EXECUTE PROCEDURE compute_journal_entry_continuous_number();
        SQL
      end
      d.down do
        execute <<-SQL
          DROP SEQUENCE journal_entries_continuous_number;
          DROP TRIGGER compute_journal_entries_continuous_number_on_update ON journal_entries;
          DROP TRIGGER compute_journal_entries_continuous_number_on_insert ON journal_entries;
          DROP FUNCTION compute_journal_entry_continuous_number();
        SQL
      end
    end
  end
end
