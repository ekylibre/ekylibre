class AdjustTriggerOnPartialLetteringUpdate < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER IF EXISTS compute_partial_lettering_status_update ON journal_entry_items
        SQL

        execute 'ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_insert_delete'

        account_letterings = <<-SQL.strip_heredoc
            SELECT account_id,
              RTRIM(letter, '*') AS letter_radix,
              SUM(debit) = SUM(credit) AS balanced,
              RTRIM(letter, '*') || CASE WHEN SUM(debit) <> SUM(credit) THEN '*' ELSE '' END
                AS new_letter
            FROM journal_entry_items AS jei
            WHERE account_id IS NOT NULL AND LENGTH(TRIM(COALESCE(letter, ''))) > 0
            GROUP BY account_id, RTRIM(letter, '*')
        SQL

        execute <<-SQL.strip_heredoc
            UPDATE journal_entry_items AS jei
              SET letter = ref.new_letter
              FROM (#{account_letterings}) AS ref
              WHERE jei.account_id = ref.account_id
                AND RTRIM(COALESCE(jei.letter, ''), '*') = ref.letter_radix
                AND letter <> ref.new_letter;
        SQL

        execute 'ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_insert_delete'

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
