class NormalizeTradeAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :letter, :string
    add_column :journals, :used_for_permanent_stock_inventory, :boolean, null: false, default: false
    add_column :journals, :used_for_unbilled_payables, :boolean, null: false, default: false

    reversible do |d|
      d.up do
        execute "UPDATE affairs SET third_role = 'client' WHERE third_role != 'client' AND (id IN (SELECT affair_id FROM sales) OR id IN (SELECT affair_id FROM incoming_payments)) AND NOT (id IN (SELECT affair_id FROM purchases) OR id IN (SELECT affair_id FROM outgoing_payments))"
        execute "UPDATE affairs SET third_role = 'supplier' WHERE third_role != 'supplier' AND NOT (id IN (SELECT affair_id FROM sales) OR id IN (SELECT affair_id FROM incoming_payments)) AND (id IN (SELECT affair_id FROM purchases) OR id IN (SELECT affair_id FROM outgoing_payments))"
        execute "UPDATE affairs SET type = 'SaleAffair' WHERE third_role = 'client' AND COALESCE(type, 'Affair') NOT IN ('SaleOpportunity', 'SaleTicket')"
        execute "UPDATE affairs SET type = 'PurchaseAffair' WHERE third_role = 'supplier'"
      end
      d.down do
        execute "UPDATE affairs SET third_role = CASE WHEN type = 'SaleAffair' THEN 'client' ELSE 'supplier' END"
        execute "UPDATE affairs SET type = 'Affair' WHERE type IN ('SaleAffair', 'PurchaseAffair')"
      end
    end

    revert { add_column :affairs, :third_role, :string }

    add_column :gaps, :type, :string

    reversible do |d|
      d.up do
        # Set gaps type
        execute "UPDATE gaps SET type = CASE WHEN entity_role = 'client' THEN 'SaleGap' ELSE 'PurchaseGap' END"
        # Normalize loss and profit values
        execute "UPDATE gaps SET direction = 'loss' WHERE amount < 0 AND direction = 'profit'"
        execute "UPDATE gaps SET direction = 'profit' WHERE amount > 0 AND direction = 'loss'"
        # Round gaps
      end
      d.down do
        # De-normalize loss and profit values
        # No need to de-normalize because it doesn't change bookkeeping result
        # Re-set entity_role
        execute "UPDATE gaps SET entity_role = CASE WHEN type = 'SaleGap' THEN 'client' ELSE 'supplier' END"
        change_column_null :gaps, :entity_role, false
      end
    end

    revert do
      add_column :gaps, :entity_role, :string
    end

    # Letters every account when possible like affair are doing that now
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

        execute "SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.client_id AS third_id, 'sales' AS source, d.id, CASE WHEN d.state IN ('aborted', 'refused') THEN 0 WHEN d.credit THEN -d.amount ELSE 0 END AS debit_amount, CASE WHEN d.state IN ('aborted', 'refused') THEN 0 WHEN NOT d.credit THEN d.amount ELSE 0 END AS credit_amount
    INTO TEMPORARY TABLE letterable_deals
    FROM sales AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.supplier_id AS third_id, 'purchases' AS source, d.id, d.amount AS debit_amount, 0 AS credit_amount
    FROM purchases AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.payer_id AS third_id, 'incoming_payments' AS source, d.id, d.amount AS debit_amount, 0 AS credit_amount
    FROM incoming_payments AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.payee_id AS third_id, 'outgoing_payments' AS source, d.id, 0 AS debit_amount, d.amount AS credit_amount
    FROM outgoing_payments AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, 'sale_gaps' AS source, d.id, CASE WHEN d.direction = 'loss' THEN -d.amount ELSE 0 END AS debit_amount, CASE WHEN d.direction = 'profit' THEN d.amount ELSE 0 END AS credit_amount
    FROM gaps AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
    WHERE d.type = 'SaleGap'
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, 'purchase_gaps' AS source, d.id, CASE WHEN d.direction = 'loss' THEN -d.amount ELSE 0 END AS debit_amount, CASE WHEN d.direction = 'profit' THEN d.amount ELSE 0 END AS credit_amount
    FROM gaps AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
    WHERE d.type = 'PurchaseGap';".gsub(/\s*\n\s*/, ' ')
        %w[affair_id account_id journal_entry_id third_id id].each do |col|
          execute "CREATE INDEX letterable_deals_#{col} ON letterable_deals (#{col})"
        end

        # Synchronize affairs for some exception
        execute 'UPDATE affairs SET debit = debit_amount, credit = credit_amount FROM (select affair_id, sum(debit_amount) AS debit_amount, sum(credit_amount) AS credit_amount FROM letterable_deals group by 1) AS sums WHERE sums.affair_id = affairs.id;'

        execute "CREATE OR REPLACE VIEW letterable_multi_thirds AS
  SELECT affair_id, count(DISTINCT third_id)
    FROM letterable_deals
    WHERE affair_id IS NOT NULL
    GROUP BY affair_id;".gsub(/\s*\n\s*/, ' ')

        execute "CREATE OR REPLACE VIEW letterable_sum AS
   select sum(jei.debit) AS jei_debit, sum(jei.credit) AS jei_credit, a.id AS affair_id, a.debit, a.credit, jei.account_id, (a.debit = a.credit AND a.debit = sum(jei.debit) AND a.credit = sum(jei.credit)) AS balanced
     FROM journal_entry_items as jei
       JOIN letterable_deals AS lcg on (jei.entry_id = lcg.journal_entry_id AND jei.account_id = lcg.account_id)
       JOIN affairs AS a ON (a.id = lcg.affair_id)
     GROUP BY a.id, jei.account_id;".gsub(/\s*\n\s*/, ' ')

        execute "
  SELECT lcg.*
    INTO TEMPORARY TABLE letterable_groups
    FROM letterable_deals AS lcg
    WHERE lcg.affair_id NOT IN (SELECT affair_id FROM letterable_multi_thirds WHERE count != 1)
      AND lcg.affair_id IN (SELECT affair_id FROM letterable_sum WHERE balanced)
;".gsub(/\s*\n\s*/, ' ')

        %w[affair_id account_id journal_entry_id third_id id].each do |col|
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
        AND jei.entry_id IN (
          SELECT journal_entry_id
            FROM letterable_groups
            WHERE account_id = letterable_account_id
              AND affair_id = letterable_affair_id
          );
    RETURN new_letter;
END;
$$ LANGUAGE plpgsql;".gsub(/\s*\n\s*/, ' ')

        execute 'SELECT letter_affair(g.affair_id, g.account_id)
  FROM (SELECT DISTINCT affair_id, account_id FROM letterable_groups) AS g
  WHERE account_id IS NOT NULL AND affair_id IS NOT NULL;'

        execute 'DROP FUNCTION letter_affair(BIGINT, BIGINT);'
        execute 'DROP TABLE letterable_groups CASCADE;'
        execute 'DROP VIEW letterable_sum;'
        execute 'DROP VIEW letterable_multi_thirds;'
        execute 'DROP TABLE letterable_deals CASCADE;'
        execute 'DROP FUNCTION succ(VARCHAR);'
      end
    end
  end
end
