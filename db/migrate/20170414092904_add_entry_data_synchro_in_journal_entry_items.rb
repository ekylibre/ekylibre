class AddEntryDataSynchroInJournalEntryItems < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION synchronize_jei_with_entry() RETURNS TRIGGER AS $$
          DECLARE
            synced_entry_id integer DEFAULT NULL;
          BEGIN
            IF TG_NARGS <> 0 THEN
              IF TG_ARGV[0] = 'jei' THEN
                synced_entry_id := NEW.entry_id;
              END IF;

              IF TG_ARGV[0] = 'entry' THEN
                synced_entry_id := NEW.id;
              END IF;
            END IF;

            IF synced_entry_id IS NOT NULL THEN
              UPDATE journal_entry_items AS jei
              SET state = je.state,
                  printed_on = je.printed_on,
                  journal_id = je.journal_id,
                  financial_year_id = je.financial_year_id,
                  entry_number = je.number,
                  real_currency = je.real_currency,
                  real_currency_rate = je.real_currency_rate
              FROM journal_entries AS je
              WHERE jei.entry_id = je.id
                AND je.id = synced_entry_id
                AND (jei.state <> je.state
                 OR jei.printed_on <> je.printed_on
                 OR jei.journal_id <> je.journal_id
                 OR jei.financial_year_id <> je.financial_year_id
                 OR jei.entry_number <> je.number
                 OR jei.real_currency <> je.real_currency
                 OR jei.real_currency_rate <> je.real_currency_rate);
            END IF;
            RETURN NEW;
          END;
          $$ language plpgsql;
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER synchronize_jeis_of_entry
            AFTER INSERT OR UPDATE
            ON journal_entries
            FOR EACH ROW
              EXECUTE PROCEDURE synchronize_jei_with_entry('entry');
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER synchronize_jei_with_entry
            AFTER INSERT OR UPDATE
            ON journal_entry_items
            FOR EACH ROW
            EXECUTE PROCEDURE synchronize_jei_with_entry('jei');
        SQL

        execute <<-SQL.strip_heredoc
          UPDATE journal_entries SET printed_on = printed_on;
        SQL
      end

      dir.down do
        execute 'DROP TRIGGER IF EXISTS synchronize_jei_with_entry ON journal_entry_items;'
        execute 'DROP TRIGGER IF EXISTS synchronize_jeis_of_entry ON journal_entries;'
        execute 'DROP FUNCTION IF EXISTS synchronize_jei_with_entry();'
      end
    end
  end
end
