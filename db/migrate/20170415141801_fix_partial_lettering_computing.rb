class FixPartialLetteringComputing < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION compute_partial_lettering() RETURNS TRIGGER AS $$
            DECLARE
              new_letter varchar DEFAULT NULL;
              old_letter varchar DEFAULT NULL;
              new_account_id integer DEFAULT NULL;
              old_account_id integer DEFAULT NULL;
            BEGIN
            IF TG_OP <> 'DELETE' THEN
              IF NEW.letter IS NOT NULL THEN
                new_letter := substring(NEW.letter from '[A-z]*');
              END IF;

            IF NEW.account_id IS NOT NULL THEN
              new_account_id := NEW.account_id;
            END IF;
          END IF;

          IF TG_OP <> 'INSERT' THEN
            IF OLD.letter IS NOT NULL THEN
              old_letter := substring(OLD.letter from '[A-z]*');
            END IF;

            IF OLD.account_id IS NOT NULL THEN
              old_account_id := OLD.account_id;
            END IF;
          END IF;

          UPDATE journal_entry_items
          SET letter = (CASE
                          WHEN modified_letter_groups.balance <> 0
                          THEN modified_letter_groups.letter || '*'
                          ELSE modified_letter_groups.letter
                        END)
          FROM (SELECT new_letter AS letter,
                       account_id AS account_id,
                       SUM(debit) - SUM(credit) AS balance
                    FROM journal_entry_items
                    WHERE account_id = new_account_id
                      AND letter SIMILAR TO (COALESCE(new_letter, '') || '\\**')
                      AND new_letter IS NOT NULL
                      AND new_account_id IS NOT NULL
                    GROUP BY account_id
                UNION ALL
                SELECT old_letter AS letter,
                       account_id AS account_id,
                       SUM(debit) - SUM(credit) AS balance
                  FROM journal_entry_items
                  WHERE account_id = old_account_id
                    AND letter SIMILAR TO (COALESCE(old_letter, '') || '\\**')
                    AND old_letter IS NOT NULL
                    AND old_account_id IS NOT NULL
                  GROUP BY account_id) AS modified_letter_groups
          WHERE modified_letter_groups.account_id = journal_entry_items.account_id
          AND journal_entry_items.letter SIMILAR TO (modified_letter_groups.letter || '\\**');

          RETURN NEW;
        END;
        $$ language plpgsql;
        SQL

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

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION compute_partial_lettering() RETURNS TRIGGER AS $$
            DECLARE
              new_letter varchar DEFAULT NULL;
              old_letter varchar DEFAULT NULL;
              new_account_id integer DEFAULT NULL;
              old_account_id integer DEFAULT NULL;
            BEGIN
            IF TG_OP <> 'DELETE' THEN
              IF NEW.letter IS NOT NULL THEN
                new_letter := substring(NEW.letter from '[A-z]*');
              END IF;

            IF NEW.account_id IS NOT NULL THEN
              new_account_id := NEW.account_id;
            END IF;
          END IF;

          IF TG_OP <> 'INSERT' THEN
            IF OLD.letter IS NOT NULL THEN
              old_letter := substring(OLD.letter from '[A-z]*');
            END IF;

            IF OLD.account_id IS NOT NULL THEN
              old_account_id := OLD.account_id;
            END IF;
          END IF;

          UPDATE journal_entry_items
          SET letter = (CASE
                          WHEN modified_letter_groups.balance <> 0
                          THEN modified_letter_groups.letter || '*'
                          ELSE modified_letter_groups.letter
                        END)
          FROM (SELECT new_letter AS letter,
                       account_id AS account_id,
                       SUM(debit) - SUM(credit) AS balance
                    FROM journal_entry_items
                    WHERE account_id = new_account_id
                      AND letter SIMILAR TO (COALESCE(new_letter, '') || '\\*?')
                      AND new_letter IS NOT NULL
                      AND new_account_id IS NOT NULL
                    GROUP BY account_id
                UNION ALL
                SELECT old_letter AS letter,
                       account_id AS account_id,
                       SUM(debit) - SUM(credit) AS balance
                  FROM journal_entry_items
                  WHERE account_id = old_account_id
                    AND letter SIMILAR TO (COALESCE(old_letter, '') || '\\*?')
                    AND old_letter IS NOT NULL
                    AND old_account_id IS NOT NULL
                  GROUP BY account_id) AS modified_letter_groups
          WHERE modified_letter_groups.account_id = journal_entry_items.account_id
          AND journal_entry_items.letter SIMILAR TO (modified_letter_groups.letter || '\\*?');

          RETURN NEW;
        END;
        $$ language plpgsql;
        SQL
      end
    end
  end
end
