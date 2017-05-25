class AddPartialLetteringSupport < ActiveRecord::Migration
  def up

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
    
    execute "CREATE OR REPLACE VIEW account_letterings AS #{account_letterings}"

    execute <<-SQL.strip_heredoc
            UPDATE journal_entry_items AS jei
              SET letter = ref.new_letter
              FROM account_letterings AS ref
              WHERE jei.account_id = ref.account_id
                AND RTRIM(COALESCE(jei.letter, ''), '*') = ref.letter_radix
                AND letter <> ref.new_letter;
    SQL
    
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION set_account_lettering() RETURNS TRIGGER AS $$
        DECLARE
          letter_balance DECIMAL DEFAULT 0.0;
        BEGIN
          IF LENGTH(TRIM(COALESCE(NEW.letter, ''))) > 0 AND NEW.account_id IS NOT NULL THEN
            SELECT SUM(debit - credit) FROM journal_entry_items WHERE account_id = NEW.account_id AND RTRIM(COALESCE(letter, ''), '*') IS DISTINCT FROM RTRIM(NEW.letter, '*') INTO letter_balance;
            IF TG_OP = 'UPDATE' THEN
              letter_balance := letter_balance - (OLD.debit - OLD.credit);
            END IF;
            IF letter_balance <> 0 THEN
              NEW.letter := RTRIM(NEW.letter, '*') || '*';
            ELSE 
              NEW.letter := RTRIM(NEW.letter, '*');
            END IF;
          END IF;
          RETURN NEW;
        END
      $$ language plpgsql;
    SQL

    execute <<-SQL.strip_heredoc
      CREATE TRIGGER trigger_set_account_lettering_before_insert
        BEFORE INSERT
        ON journal_entry_items
        FOR EACH ROW
        EXECUTE PROCEDURE set_account_lettering();
    SQL
    
    execute <<-SQL.strip_heredoc
      CREATE TRIGGER trigger_set_account_lettering_before_update
        BEFORE UPDATE OF credit, debit, account_id, letter
        ON journal_entry_items
        FOR EACH ROW
        WHEN (COALESCE(RTRIM(OLD.letter, '*'), '') IS DISTINCT FROM COALESCE(RTRIM(NEW.letter, '*'), '')
          OR OLD.account_id IS DISTINCT FROM NEW.account_id
          OR OLD.credit IS DISTINCT FROM NEW.credit
          OR OLD.debit IS DISTINCT FROM NEW.debit)      
        EXECUTE PROCEDURE set_account_lettering();
    SQL
    
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION update_other_account_lettering() RETURNS TRIGGER AS $$
        DECLARE
          true_letter varchar DEFAULT NULL;
        BEGIN

          IF TG_OP IN ('UPDATE', 'DELETE') THEN
            IF OLD.account_id IS NOT NULL AND LENGTH(TRIM(COALESCE(OLD.letter, ''))) > 0 THEN
            SELECT new_letter FROM (#{account_letterings}) AS account_letterings WHERE account_id = OLD.account_id AND letter_radix = RTRIM(OLD.letter, '*') INTO true_letter;
            UPDATE journal_entry_items AS jei
              SET letter = true_letter
              WHERE jei.account_id = OLD.account_id
                AND RTRIM(COALESCE(jei.letter, ''), '*') = RTRIM(OLD.letter, '*')
                AND jei.id <> OLD.id
                AND jei.letter IS DISTINCT FROM true_letter;
            END IF;
          END IF;

          IF TG_OP IN ('UPDATE', 'INSERT') THEN
            IF NEW.account_id IS NOT NULL AND LENGTH(TRIM(COALESCE(NEW.letter, ''))) > 0 THEN
            SELECT new_letter FROM (#{account_letterings}) AS account_letterings WHERE account_id = NEW.account_id AND letter_radix = RTRIM(NEW.letter, '*') INTO true_letter;
            UPDATE journal_entry_items AS jei
              SET letter = true_letter
              WHERE jei.account_id = NEW.account_id
                AND RTRIM(COALESCE(jei.letter, ''), '*') = RTRIM(NEW.letter, '*')
                AND jei.id <> NEW.id
                AND jei.letter IS DISTINCT FROM true_letter;
            END IF;
          END IF;

          RETURN NEW;
        END
      $$ language plpgsql;
    SQL

    execute <<-SQL.strip_heredoc
      CREATE TRIGGER trigger_update_other_account_lettering_after_delete
        AFTER INSERT OR DELETE
        ON journal_entry_items
        FOR EACH ROW
        EXECUTE PROCEDURE update_other_account_lettering();
    SQL

    execute <<-SQL.strip_heredoc
      CREATE TRIGGER trigger_update_other_account_lettering_after_update
        AFTER UPDATE OF credit, debit, account_id, letter
        ON journal_entry_items
        FOR EACH ROW
        WHEN (COALESCE(RTRIM(OLD.letter, '*'), '') IS DISTINCT FROM COALESCE(RTRIM(NEW.letter, '*'), '')
          OR OLD.account_id IS DISTINCT FROM NEW.account_id
          OR OLD.credit IS DISTINCT FROM NEW.credit
          OR OLD.debit IS DISTINCT FROM NEW.debit)      
        EXECUTE PROCEDURE update_other_account_lettering();
    SQL
    
    # execute <<-SQL.strip_heredoc
    #       CREATE OR REPLACE FUNCTION update_account_lettering(checked_account_id INTEGER, checked_letter VARCHAR) RETURNS VARCHAR AS $$
    #         UPDATE journal_entry_items AS jei
    #           SET letter = ref.new_letter
    #           FROM account_letterings AS ref
    #           WHERE (jei.account_id = ref.account_id AND RTRIM(jei.letter, '*') = ref.letter_radix)
    #             AND letter != ref.new_letter
    #             AND jei.account_id = checked_account_id
    #             AND RTRIM(jei.letter, '*') = checked_letter
    #           RETURNING ref.new_letter;
    #     $$ language sql;
    #     SQL

    
    # execute <<-SQL.strip_heredoc
    #     CREATE OR REPLACE FUNCTION update_account_letterings() RETURNS TRIGGER AS $$
    #       BEGIN
    #         IF OLD.account_id IS NOT NULL AND LENGTH(TRIM(OLD.letter)) > 0 THEN
    #           PERFORM update_account_lettering(OLD.account_id, RTRIM(OLD.letter, '*'));
    #         END IF;
    #         IF NEW.account_id IS NOT NULL AND LENGTH(TRIM(NEW.letter)) > 0 THEN
    #           PERFORM update_account_lettering(NEW.account_id, RTRIM(NEW.letter, '*'));
    #         END IF;
    #         RETURN NEW;
    #       END;
    #     $$ language plpgsql;
    #     SQL

    # execute <<-SQL.strip_heredoc
    #       CREATE TRIGGER trigger_account_lettering
    #         AFTER UPDATE OF credit, debit, account_id, letter
    #         ON journal_entry_items
    #         FOR EACH ROW
    #           EXECUTE PROCEDURE update_account_letterings();
    #     SQL
    
    # execute <<-SQL.strip_heredoc
    #       CREATE OR REPLACE FUNCTION compute_partial_lettering() RETURNS TRIGGER AS $$
    #       DECLARE
    #         true_letter varchar DEFAULT NULL;
    #       BEGIN

    #       IF TG_OP IN ('UPDATE', 'DELETE') THEN
    #         IF OLD.account_id IS NOT NULL AND LENGTH(TRIM(OLD.letter)) > 0 THEN
    #         SELECT new_letter FROM (#{account_letterings}) AS account_letterings WHERE account_id = OLD.account_id AND letter_radix = RTRIM(OLD.letter, '*') INTO true_letter;
    #         UPDATE journal_entry_items AS jei
    #           SET letter = true_letter
    #           WHERE jei.account_id = OLD.account_id
    #             AND RTRIM(jei.letter, '*') = RTRIM(OLD.letter, '*')
    #             AND jei.letter <> true_letter;
    #         END IF;
    #       END IF;

    #       IF TG_OP IN ('UPDATE', 'INSERT') THEN
    #         IF NEW.account_id IS NOT NULL AND LENGTH(TRIM(NEW.letter)) > 0 THEN
    #         SELECT new_letter FROM (#{account_letterings}) AS account_letterings WHERE account_id = NEW.account_id AND letter_radix = RTRIM(NEW.letter, '*') INTO true_letter;
    #         UPDATE journal_entry_items AS jei
    #           SET letter = true_letter
    #           WHERE jei.account_id = NEW.account_id
    #             AND RTRIM(jei.letter, '*') = RTRIM(NEW.letter, '*')
    #             AND jei.letter <> true_letter;
    #         END IF;
    #       END IF;

    #       RETURN NEW;
    #     END;
    #     $$ language plpgsql;
    #     SQL

    # execute <<-SQL.strip_heredoc
    #       CREATE TRIGGER compute_partial_lettering_status_insert_delete
    #         AFTER INSERT OR DELETE
    #         ON journal_entry_items
    #         FOR EACH ROW
    #           EXECUTE PROCEDURE compute_partial_lettering();
    #     SQL

    # execute <<-SQL.strip_heredoc
    #       CREATE TRIGGER compute_partial_lettering_status_update
    #         AFTER UPDATE OF credit, debit, account_id, letter
    #         ON journal_entry_items
    #         FOR EACH ROW
    #         WHEN COALESCE(OLD.letter, '') IS DISTINCT FROM COALESCE(NEW.letter, '')
    #           EXECUTE PROCEDURE compute_partial_lettering();
    #     SQL

    
    # execute "UPDATE journal_entry_items SET letter = letter || '***' WHERE letter IS NOT NULL;"

    # execute 'DROP TRIGGER compute_partial_lettering_status_update ON journal_entry_items;'

    # execute <<-SQL.strip_heredoc
    #       CREATE TRIGGER compute_partial_lettering_status_update
    #         AFTER UPDATE OF credit, debit, account_id, letter
    #         ON journal_entry_items
    #         FOR EACH ROW
    #         WHEN (COALESCE(RTRIM(OLD.letter, '*'), '') IS DISTINCT FROM COALESCE(RTRIM(NEW.letter, '*'), '')
    #           OR OLD.account_id IS DISTINCT FROM NEW.account_id
    #           OR OLD.credit IS DISTINCT FROM NEW.credit
    #           OR OLD.debit IS DISTINCT FROM NEW.debit)
    #           EXECUTE PROCEDURE compute_partial_lettering();
    #     SQL

  end

  def down
    execute 'DROP TRIGGER IF EXISTS compute_partial_lettering_status_insert_delete ON journal_entry_items;'
    execute 'DROP TRIGGER IF EXISTS compute_partial_lettering_status_update ON journal_entry_items;'
    execute 'DROP FUNCTION IF EXISTS compute_partial_lettering();'
  end
end
