class AdjustTriggerOnPartialLetteringUpdate < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER IF EXISTS compute_partial_lettering_status_update ON journal_entry_items
        SQL

        execute <<-SQL.strip_heredoc
          CREATE TRIGGER compute_partial_lettering_status_update
            AFTER UPDATE OF credit, debit, account_id, letter
            ON journal_entry_items
            FOR EACH ROW
            WHEN (COALESCE(OLD.letter, '') <> COALESCE(NEW.letter, '')
              OR OLD.account_id <> NEW.account_id
              OR OLD.credit <> NEW.credit
              OR OLD.debit <> NEW.debit)
              EXECUTE PROCEDURE compute_partial_lettering();
        SQL
      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER IF EXISTS compute_partial_lettering_status_update ON journal_entry_items
        SQL

        execute <<-SQL.strip_heredoc
              CREATE TRIGGER compute_partial_lettering_status_update
                AFTER UPDATE OF credit, debit, account_id, letter
                ON journal_entry_items
                FOR EACH ROW
                WHEN (substring(COALESCE(OLD.letter, '') from '[A-z]*') <> substring(COALESCE(NEW.letter, '') from '[A-z]*')
                  OR OLD.account_id <> NEW.account_id
                  OR OLD.credit <> NEW.credit
                  OR OLD.debit <> NEW.debit)
                  EXECUTE PROCEDURE compute_partial_lettering();
            SQL
      end
    end
  end
end
