class FixIsacomptaLetteringComputing < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          DROP TRIGGER IF EXISTS partial_isacompta_lettering ON journal_entry_items CASCADE;
          DROP TRIGGER IF EXISTS compute_partial_isacompta_lettering ON journal_entry_items CASCADE;
          CREATE OR REPLACE FUNCTION compute_partial_isacompta_lettering() RETURNS TRIGGER AS $$
            DECLARE
              journal_entry_item_ids integer DEFAULT NULL;
              new_letter varchar DEFAULT NULL;
              old_letter varchar DEFAULT NULL;
            BEGIN
              journal_entry_item_ids := NEW.id;
              new_letter := NEW.letter;
              old_letter := OLD.letter;

              UPDATE journal_entry_items
                SET isacompta_letter = (CASE WHEN RIGHT(new_letter, 1) = '*'
                  THEN (CASE WHEN LEFT(journal_entry_items.isacompta_letter, 1) = '#'
                          THEN journal_entry_items.isacompta_letter
                          ELSE '#' || journal_entry_items.isacompta_letter
                          END)
                  ELSE (CASE
                         WHEN LEFT(journal_entry_items.isacompta_letter, 1) = '#'
                         THEN LTRIM(journal_entry_items.isacompta_letter, '#')
                         ELSE journal_entry_items.isacompta_letter
                         END)
                  END)
              WHERE id = journal_entry_item_ids AND new_letter <> old_letter;

              RETURN NEW;
            END;
          $$ language plpgsql;

          CREATE TRIGGER compute_partial_isacompta_lettering
            AFTER UPDATE OF letter
            ON journal_entry_items
            FOR EACH ROW
          EXECUTE PROCEDURE compute_partial_isacompta_lettering();
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS compute_partial_isacompta_lettering ON journal_entry_items CASCADE;
          DROP TRIGGER IF EXISTS partial_isacompta_lettering ON journal_entry_items CASCADE;
          CREATE OR REPLACE FUNCTION compute_partial_isacompta_lettering() RETURNS TRIGGER AS $$
            DECLARE
              journal_entry_item_ids integer DEFAULT NULL;
              new_letter varchar DEFAULT NULL;
            BEGIN
              IF NEW.letter <> OLD.letter THEN
                journal_entry_item_ids := NEW.id;
                new_letter := NEW.letter;
              END IF;

              UPDATE journal_entry_items SET isacompta_letter = (CASE
                WHEN RIGHT(new_letter, 1) = '*'
                  THEN CASE
                    WHEN LEFT(journal_entry_items.isacompta_letter, 1) = '#'
                    THEN journal_entry_items.isacompta_letter
                    ELSE '#' || journal_entry_items.isacompta_letter
                  END
                  ELSE CASE
                    WHEN LEFT(journal_entry_items.isacompta_letter, 1) != '#'
                    THEN journal_entry_items.isacompta_letter
                    ELSE '#' || journal_entry_items.isacompta_letter
                  END
                END)
              WHERE id = journal_entry_item_ids;

              RETURN NEW;
            END;
          $$ language plpgsql;

          CREATE TRIGGER partial_isacompta_lettering
            AFTER UPDATE
            OF letter ON journal_entry_items
            FOR EACH ROW
          EXECUTE PROCEDURE compute_partial_isacompta_lettering();
        SQL
      end
    end
  end
end
