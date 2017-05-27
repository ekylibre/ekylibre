class ComputeAffairsAmount < ActiveRecord::Migration
  def up
    # Force invoice state on credits
    execute "UPDATE sales SET state = 'invoice' WHERE credit"

    execute "SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.client_id AS third_id, 'sales' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    INTO TEMPORARY TABLE letterable_deals
    FROM sales AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = e.client_account_id)
    GROUP BY 1, 2, 3, 4, 5, 6
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.supplier_id AS third_id, 'purchases' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    FROM purchases AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = e.supplier_account_id)
    GROUP BY 1, 2, 3, 4, 5, 6
  UNION ALL
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.payer_id AS third_id, 'incoming_payments' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    FROM incoming_payments AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = e.client_account_id)
    GROUP BY 1, 2, 3, 4, 5, 6
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.payee_id AS third_id, 'outgoing_payments' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    FROM outgoing_payments AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = e.supplier_account_id)
    GROUP BY 1, 2, 3, 4, 5, 6
  UNION ALL
  SELECT d.affair_id, e.client_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, 'sale_gaps' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    FROM gaps AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = e.client_account_id)
    WHERE d.type = 'SaleGap'
    GROUP BY 1, 2, 3, 4, 5, 6
  UNION ALL
  SELECT d.affair_id, e.supplier_account_id AS account_id, d.journal_entry_id, d.entity_id AS third_id, 'purchase_gaps' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    FROM gaps AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = e.supplier_account_id)
    WHERE d.type = 'PurchaseGap'
    GROUP BY 1, 2, 3, 4, 5, 6
  UNION ALL
  SELECT d.affair_id, CASE WHEN a.type = 'SaleAffair' THEN e.client_account_id ELSE e.supplier_account_id END AS account_id, d.journal_entry_id, a.third_id AS third_id, 'regularization' AS source, d.id, COALESCE(sum(jei.real_debit), 0) AS debit_amount, COALESCE(sum(jei.real_credit), 0) AS credit_amount
    FROM regularizations AS d
      JOIN affairs AS a ON (d.affair_id = a.id)
      JOIN entities AS e ON (e.id = a.third_id)
      LEFT JOIN journal_entry_items AS jei ON (jei.entry_id = d.journal_entry_id AND jei.account_id = CASE WHEN a.type = 'SaleAffair' THEN e.client_account_id ELSE e.supplier_account_id END)
    GROUP BY 1, 2, 3, 4, 5, 6
;".gsub(/\s*\n\s*/, ' ')
    %w[affair_id account_id journal_entry_id third_id id].each do |col|
      execute "CREATE INDEX letterable_deals_#{col} ON letterable_deals (#{col})"
    end

    # Synchronize affairs for some exception
    execute 'UPDATE affairs SET debit = debit_amount, credit = credit_amount FROM (select affair_id, sum(debit_amount) AS debit_amount, sum(credit_amount) AS credit_amount FROM letterable_deals group by 1) AS sums WHERE sums.affair_id = affairs.id;'

    # Remove temporary table
    execute 'DROP TABLE letterable_deals CASCADE;'
  end
end
