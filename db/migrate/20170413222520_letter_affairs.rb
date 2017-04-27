class LetterAffairs < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        execute "CREATE OR REPLACE FUNCTION succ(IN string VARCHAR) RETURNS VARCHAR AS $$
                 DECLARE
                     chars varchar;
                     successor VARCHAR;
                     account_id INT;
                     i int;
                     shift INT;
                     letter CHAR;
                 BEGIN
                   IF LENGTH(TRIM(string)) > 0 THEN
                     chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZA';
                     shift := 1;
                     successor := '';
                     FOR i IN REVERSE char_length(string)..1 LOOP
                       letter = upper(substring(string FROM i FOR 1))::char;
                       IF shift > 0 THEN
                         IF letter != 'Z' THEN
                           shift := 0;
                         END IF;
                         successor := substring(chars FROM position(letter in chars) + 1 FOR 1) || successor;
                       ELSE
                         successor := letter || successor;
                       END IF;
                     END LOOP;
                     IF shift > 0 THEN
                       successor := substring(chars FROM 1 FOR 1) || successor;
                     END IF;
                   ELSE
                     successor := 'A';
                   END IF;
                   RETURN successor;
                 END;
                 $$ LANGUAGE plpgsql;".gsub(/\s*\n\s*/, ' ')

        execute "SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.client_id AS third_id, a.letter AS letter
                   INTO TEMPORARY TABLE letterable_deals
                   FROM sales AS d
                     JOIN affairs AS a ON (d.affair_id = a.id)
                     JOIN entities AS e ON (e.id = a.third_id)
                 UNION ALL
                 SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.supplier_id AS third_id, a.letter AS letter
                   FROM purchases AS d
                     JOIN affairs AS a ON (d.affair_id = a.id)
                     JOIN entities AS e ON (e.id = a.third_id)
                 UNION ALL
                 SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.payer_id AS third_id, a.letter AS letter
                   FROM incoming_payments AS d
                     JOIN affairs AS a ON (d.affair_id = a.id)
                     JOIN entities AS e ON (e.id = a.third_id)
                 UNION ALL
                 SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.payee_id AS third_id, a.letter AS letter
                   FROM outgoing_payments AS d
                     JOIN affairs AS a ON (d.affair_id = a.id)
                     JOIN entities AS e ON (e.id = a.third_id)
                 UNION ALL
                 SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, a.letter AS letter
                   FROM gaps AS d
                     JOIN affairs AS a ON (d.affair_id = a.id)
                     JOIN entities AS e ON (e.id = a.third_id)
                   WHERE d.type = 'SaleGap'
                 UNION ALL
                 SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, a.letter AS letter
                   FROM gaps AS d
                     JOIN affairs AS a ON (d.affair_id = a.id)
                     JOIN entities AS e ON (e.id = a.third_id)
                   WHERE d.type = 'PurchaseGap'
                 UNION ALL
                 SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, a.third_id AS third_id, a.letter AS letter
                   FROM regularizations AS d
                     JOIN affairs AS a ON (d.affair_id = a.id AND a.type = 'PurchaseAffair')
                     JOIN entities AS e ON (e.id = a.third_id)
                 UNION ALL
                 SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, a.third_id AS third_id, a.letter AS letter
                   FROM regularizations AS d
                     JOIN affairs AS a ON (d.affair_id = a.id AND a.type = 'SaleAffair')
                     JOIN entities AS e ON (e.id = a.third_id);".gsub(/\s*\n\s*/, ' ')

        %w[affair_id account_id journal_entry_id third_id letter].each do |col|
          execute "CREATE INDEX letterable_deals_#{col} ON letterable_deals (#{col})"
        end

        execute "CREATE OR REPLACE VIEW letterable_multi_thirds AS
                   SELECT affair_id, count(DISTINCT third_id)
                     FROM letterable_deals
                     WHERE affair_id IS NOT NULL
                     GROUP BY affair_id;".gsub(/\s*\n\s*/, ' ')

        execute "SELECT lcg.*
                 INTO TEMPORARY TABLE letterable_groups
                 FROM letterable_deals AS lcg
                 WHERE lcg.affair_id NOT IN (SELECT affair_id FROM letterable_multi_thirds WHERE count != 1);".gsub(/\s*\n\s*/, ' ')

        %w[affair_id account_id journal_entry_id third_id letter].each do |col|
          execute "CREATE INDEX letterable_groups_#{col} ON letterable_groups (#{col})"
        end

        execute "CREATE OR REPLACE FUNCTION letter_affair(IN letterable_affair_id BIGINT, IN letterable_account_id BIGINT) RETURNS VARCHAR AS $$
                 DECLARE
                     new_letter VARCHAR;
                 BEGIN
                     SELECT succ(last_letter) INTO new_letter
                       FROM accounts AS a
                       WHERE a.id = letterable_account_id;
                     UPDATE accounts
                       SET last_letter = new_letter
                       WHERE id = letterable_account_id;
                     UPDATE affairs
                       SET letter = new_letter
                       WHERE id = letterable_affair_id;
                     UPDATE journal_entry_items AS jei
                       SET letter = new_letter
                       WHERE jei.account_id = letterable_account_id
                         AND jei.letter IS NULL
                         AND jei.entry_id IN (
                           SELECT journal_entry_id
                             FROM letterable_groups
                             WHERE account_id = letterable_account_id
                               AND affair_id = letterable_affair_id
                           );
                     RETURN new_letter;
                 END;
                 $$ LANGUAGE plpgsql;".gsub(/\s*\n\s*/, ' ')

        execute "CREATE OR REPLACE FUNCTION reletter_affair(IN letterable_affair_id BIGINT, IN letterable_account_id BIGINT, IN actual_letter VARCHAR) RETURNS VARCHAR AS $$
                 BEGIN
                     UPDATE affairs
                       SET letter = actual_letter
                       WHERE id = letterable_affair_id;
                     UPDATE journal_entry_items AS jei
                       SET letter = actual_letter
                       WHERE jei.account_id = letterable_account_id
                         AND jei.letter IS NULL
                         AND jei.entry_id IN (
                           SELECT journal_entry_id
                             FROM letterable_groups
                             WHERE account_id = letterable_account_id
                               AND affair_id = letterable_affair_id
                           );
                     RETURN actual_letter;
                 END;
                 $$ LANGUAGE plpgsql;".gsub(/\s*\n\s*/, ' ')

        execute 'SELECT (CASE WHEN g.letter IS NULL THEN letter_affair(g.affair_id, g.account_id) ELSE reletter_affair(g.affair_id, g.account_id, g.letter) END)
                 FROM (SELECT DISTINCT affair_id, account_id, letter FROM letterable_groups) AS g
                 WHERE account_id IS NOT NULL AND affair_id IS NOT NULL;'.gsub(/\s*\n\s*/, ' ')

        execute 'DROP FUNCTION letter_affair(BIGINT, BIGINT);'
        execute 'DROP FUNCTION reletter_affair(BIGINT, BIGINT, VARCHAR);'
        execute 'DROP TABLE letterable_groups CASCADE;'
        execute 'DROP VIEW letterable_multi_thirds;'
        execute 'DROP TABLE letterable_deals CASCADE;'
        execute 'DROP FUNCTION succ(VARCHAR);'
      end
    end
  end
end
