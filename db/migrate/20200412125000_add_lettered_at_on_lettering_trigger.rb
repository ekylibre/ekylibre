class AddLetteredAtOnLetteringTrigger < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do

        execute <<~SQL
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
                        END),
              lettered_at = (CASE
                          WHEN modified_letter_groups.balance <> 0
                          THEN NULL
                          ELSE NOW()
                        END)
          FROM (SELECT new_letter AS letter,
                       account_id AS account_id,
                       SUM(debit) - SUM(credit) AS balance
                    FROM journal_entry_items
                    WHERE account_id = new_account_id
                      AND journal_entry_items.state <> 'closed'
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
                    AND journal_entry_items.state <> 'closed'
                    AND letter SIMILAR TO (COALESCE(old_letter, '') || '\\**')
                    AND old_letter IS NOT NULL
                    AND old_account_id IS NOT NULL
                  GROUP BY account_id) AS modified_letter_groups
          WHERE modified_letter_groups.account_id = journal_entry_items.account_id
          AND journal_entry_items.state <> 'closed'
          AND journal_entry_items.letter SIMILAR TO (modified_letter_groups.letter || '\\**');

          RETURN NEW;
        END;
        $$ language plpgsql;
        SQL
      end

      dir.down do

        execute <<~SQL
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
                      AND journal_entry_items.state <> 'closed'
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
                    AND journal_entry_items.state <> 'closed'
                    AND letter SIMILAR TO (COALESCE(old_letter, '') || '\\**')
                    AND old_letter IS NOT NULL
                    AND old_account_id IS NOT NULL
                  GROUP BY account_id) AS modified_letter_groups
          WHERE modified_letter_groups.account_id = journal_entry_items.account_id
          AND journal_entry_items.state <> 'closed'
          AND journal_entry_items.letter SIMILAR TO (modified_letter_groups.letter || '\\**');

          RETURN NEW;
        END;
        $$ language plpgsql;
        SQL
      end
    end
  end
end
