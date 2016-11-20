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
        execute "UPDATE gaps SET type = CASE WHEN entity_role = 'client' THEN 'SaleGap' ELSE 'PurchaseGap' END"
      end
      d.down do
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
        # Adds string functions for manipulating letters
        execute "CREATE OR REPLACE FUNCTION base26_decode(IN string VARCHAR) RETURNS bigint AS $$
DECLARE
		a char[];
		digits bigint;
		i int;
		val int;
		chars varchar;
BEGIN
		chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

		FOR i IN REVERSE char_length(string)..1 LOOP
			a := a || substring(upper(string) FROM i FOR 1)::char;
		END LOOP;
		i := 0;
		digits := 0;
		WHILE i < (array_length(a,1)) LOOP
			val := position(a[i+1] IN chars)-1;
			digits := digits + (val * (26 ^ i));
			i := i + 1;
		END LOOP;
    RETURN digits;
END;
$$ LANGUAGE plpgsql IMMUTABLE;".gsub(/\s*\n\s*/, ' ')

        execute "CREATE OR REPLACE FUNCTION base26_encode(IN digits bigint) RETURNS varchar AS $$
DECLARE
    chars char[];
    string varchar;
    val bigint;
BEGIN
    chars := ARRAY['A','B','C','D','E','F','G','H','I','J','K','L','M',
                   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
    val := digits;
    string := '';
    IF val < 0 THEN
        val := val * -1;
    END IF;
    WHILE val != 0 LOOP
        string := chars[(val % 26)+1] || string;
        val := val / 26;
    END LOOP;
    RETURN string;
END;
$$ LANGUAGE plpgsql IMMUTABLE;".gsub(/\s*\n\s*/, ' ')

        execute "CREATE OR REPLACE FUNCTION succ(IN string VARCHAR) RETURNS VARCHAR AS $$
DECLARE
    successor VARCHAR;
    account_id INT;
BEGIN
  IF LENGTH(TRIM(string)) > 0 THEN
    successor := base26_encode(base26_decode(string) + 1);
  ELSE
    successor := 'AAA';
  END IF;
  RETURN successor;
END;
$$ LANGUAGE plpgsql;".gsub(/\s*\n\s*/, ' ')

        execute "CREATE OR REPLACE VIEW letterable_deals AS
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.client_id AS third_id, 'sales' AS source, d.id
    FROM sales AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.supplier_id AS third_id, 'purchases' AS source, d.id
    FROM purchases AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.payer_id AS third_id, 'incoming_payments' AS source, d.id
    FROM incoming_payments AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.payee_id AS third_id, 'outgoing_payments' AS source, d.id
    FROM outgoing_payments AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
  UNION ALL
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, 'sale_gaps' AS source, d.id
    FROM gaps AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
    WHERE d.type = 'SaleGap'
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, 'purchase_gaps' AS source, d.id
    FROM gaps AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
    WHERE d.type = 'PurchaseGap';".gsub(/\s*\n\s*/, ' ')

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

        execute "CREATE OR REPLACE VIEW letterable_groups AS
  SELECT lcg.*
    FROM letterable_deals AS lcg
    WHERE lcg.affair_id NOT IN (SELECT affair_id FROM letterable_multi_thirds WHERE count != 1)
      AND lcg.affair_id IN (SELECT affair_id FROM letterable_sum WHERE balanced)
;".gsub(/\s*\n\s*/, ' ')

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
        execute 'DROP VIEW letterable_groups;'
        execute 'DROP VIEW letterable_sum;'
        execute 'DROP VIEW letterable_multi_thirds;'
        execute 'DROP VIEW letterable_deals;'
        execute 'DROP FUNCTION IF EXISTS succ(VARCHAR);'
        execute 'DROP FUNCTION IF EXISTS base26_decode(VARCHAR);'
        execute 'DROP FUNCTION IF EXISTS base26_encode(BIGINT);'
      end
    end
  end
end
