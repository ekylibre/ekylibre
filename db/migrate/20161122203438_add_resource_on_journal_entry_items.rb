class AddResourceOnJournalEntryItems < ActiveRecord::Migration
  def change
    add_column :journal_entries, :resource_prism, :string
    add_reference :journal_entry_items, :resource, polymorphic: true, index: true
    add_column :journal_entry_items, :resource_prism, :string

    rename_column :sales, :undelivered_invoice_entry_id, :undelivered_invoice_journal_entry_id
    rename_column :sales, :quantity_gap_on_invoice_entry_id, :quantity_gap_on_invoice_journal_entry_id
    rename_column :purchases, :undelivered_invoice_entry_id, :undelivered_invoice_journal_entry_id
    rename_column :purchases, :quantity_gap_on_invoice_entry_id, :quantity_gap_on_invoice_journal_entry_id
    rename_column :parcels, :undelivered_invoice_entry_id, :undelivered_invoice_journal_entry_id

    other_usual_running_expenses_id = select_value("SELECT id FROM accounts WHERE usages = 'other_usual_running_expenses'").to_i
    other_usual_running_profits_id = select_value("SELECT id FROM accounts WHERE usages = 'other_usual_running_profits'").to_i

    reversible do |d|
      d.up do
        # Reset JEI
        execute 'UPDATE journal_entry_items SET tax_id = NULL, pretax_amount = 0, real_pretax_amount = 0, absolute_pretax_amount = 0'

        # cash_transfer

        # deposit

        # incoming_payment

        # inventory

        # intervention

        # loan

        # loan_repayment

        # outgoing_payment

        # parcel

        # purchase
        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'PurchaseItem', resource_id = pi.id, resource_prism = 'item_tax', tax_id = pi.tax_id, real_pretax_amount = pi.pretax_amount" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN purchases AS p ON p.journal_entry_id = je.id' \
                '    JOIN purchase_items AS pi ON pi.purchase_id = p.id' \
                '    JOIN taxes AS t ON pi.tax_id = t.id' \
                '  WHERE je.id = jei.entry_id' \
                '    AND jei.account_id = CASE WHEN pi.fixed THEN t.fixed_asset_deduction_account_id ELSE t.deduction_account_id END' \
                '    AND ((pi.amount < 0 AND jei.real_credit = -(pi.amount - pi.pretax_amount))' \
                '      OR (pi.amount >= 0 AND jei.real_debit = (pi.amount - pi.pretax_amount)))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'PurchaseItem', resource_id = pi.id, resource_prism = 'item_product'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN purchases AS p ON p.journal_entry_id = je.id' \
                '    JOIN purchase_items AS pi ON pi.purchase_id = p.id' \
                '  WHERE je.id = jei.entry_id' \
                '    AND jei.account_id = pi.account_id' \
                '    AND ((pi.amount < 0 AND jei.real_credit = -pi.pretax_amount)' \
                '      OR (pi.amount >= 0 AND jei.real_debit = pi.pretax_amount))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_prism = 'supplier'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN purchases AS p ON p.journal_entry_id = je.id' \
                '    JOIN entities AS e ON p.supplier_id = e.id' \
                '  WHERE je.id = jei.entry_id' \
                '    AND jei.account_id = e.supplier_account_id'

        execute "UPDATE journal_entries AS je SET resource_prism = 'purchase' WHERE resource_type = 'Purchase' AND je.id IN (SELECT entry_id FROM journal_entry_items WHERE resource_prism IN ('supplier', 'item_product', 'item_tax'))"

        # purchase_gap
        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'GapItem', resource_id = gi.id, resource_prism = 'item_tax', tax_id = gi.tax_id, real_pretax_amount = gi.pretax_amount" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN gaps AS g ON g.journal_entry_id = je.id' \
                '    JOIN gap_items AS gi ON gi.gap_id = g.id' \
                '    JOIN taxes AS t ON gi.tax_id = t.id' \
                "  WHERE je.id = jei.entry_id AND g.type = 'PurchaseGap'" \
                '    AND jei.account_id = CASE WHEN gi.amount >= 0 THEN t.collect_account_id ELSE t.deduction_account_id END' \
                '    AND ((gi.amount < 0 AND jei.real_debit = -(gi.amount - gi.pretax_amount))' \
                '      OR (gi.amount >= 0 AND jei.real_credit = (gi.amount - gi.pretax_amount)))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'GapItem', resource_id = gi.id, resource_prism = 'item_product'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN gaps AS g ON g.journal_entry_id = je.id' \
                '    JOIN gap_items AS gi ON gi.gap_id = g.id' \
                "  WHERE je.id = jei.entry_id AND g.type = 'PurchaseGap'" \
                "    AND jei.account_id = CASE WHEN gi.amount >= 0 THEN #{other_usual_running_profits_id} ELSE #{other_usual_running_expenses_id} END" \
                '    AND ((gi.amount < 0 AND jei.real_debit = -gi.pretax_amount)' \
                '      OR (gi.amount >= 0 AND jei.real_credit = gi.pretax_amount))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_prism = 'supplier'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN gaps AS g ON g.journal_entry_id = je.id' \
                '    JOIN entities AS e ON g.entity_id = e.id' \
                "  WHERE je.id = jei.entry_id AND g.type = 'PurchaseGap'" \
                '    AND jei.account_id = e.supplier_account_id'

        execute "UPDATE journal_entries AS je SET resource_prism = 'purchase_gap' FROM gaps AS g WHERE resource_type = 'Gap' AND resource_id = g.id AND g.type = 'SaleGap' AND je.id IN (SELECT entry_id FROM journal_entry_items WHERE resource_prism IN ('supplier', 'item_product', 'item_tax'))"

        # sale
        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'SaleItem', resource_id = si.id, resource_prism = 'item_tax', tax_id = si.tax_id, real_pretax_amount = si.pretax_amount" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN sales AS s ON s.journal_entry_id = je.id' \
                '    JOIN sale_items AS si ON si.sale_id = s.id' \
                '    JOIN taxes AS t ON si.tax_id = t.id' \
                '  WHERE je.id = jei.entry_id' \
                '    AND jei.account_id = t.collect_account_id' \
                '    AND ((si.amount < 0 AND jei.real_debit = -(si.amount - si.pretax_amount))' \
                '      OR (si.amount >= 0 AND jei.real_credit = (si.amount - si.pretax_amount)))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'SaleItem', resource_id = si.id, resource_prism = 'item_product'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN sales AS s ON s.journal_entry_id = je.id' \
                '    JOIN sale_items AS si ON si.sale_id = s.id' \
                '  WHERE je.id = jei.entry_id' \
                '    AND jei.account_id = si.account_id' \
                '    AND ((si.amount < 0 AND jei.real_debit = -si.pretax_amount)' \
                '      OR (si.amount >= 0 AND jei.real_credit = si.pretax_amount))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_prism = 'client'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN sales AS s ON s.journal_entry_id = je.id' \
                '    JOIN entities AS e ON s.client_id = e.id' \
                '  WHERE je.id = jei.entry_id' \
                '    AND jei.account_id = e.client_account_id'

        execute "UPDATE journal_entries AS je SET resource_prism = 'sale' WHERE resource_type = 'Sale' AND id IN (SELECT entry_id FROM journal_entry_items WHERE resource_prism IN ('client', 'item_product', 'item_tax'))"

        # sale_gap
        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'GapItem', resource_id = gi.id, resource_prism = 'item_tax', tax_id = gi.tax_id, real_pretax_amount = gi.pretax_amount" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN gaps AS g ON g.journal_entry_id = je.id' \
                '    JOIN gap_items AS gi ON gi.gap_id = g.id' \
                '    JOIN taxes AS t ON gi.tax_id = t.id' \
                "  WHERE je.id = jei.entry_id AND g.type = 'SaleGap'" \
                '    AND jei.account_id = CASE WHEN gi.amount >= 0 THEN t.deduction_account_id ELSE t.collect_account_id END' \
                '    AND ((gi.amount < 0 AND jei.real_credit = -(gi.amount - gi.pretax_amount))' \
                '      OR (gi.amount >= 0 AND jei.real_debit = (gi.amount - gi.pretax_amount)))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_type = 'GapItem', resource_id = gi.id, resource_prism = 'item_product'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN gaps AS g ON g.journal_entry_id = je.id' \
                '    JOIN gap_items AS gi ON gi.gap_id = g.id' \
                "  WHERE je.id = jei.entry_id AND g.type = 'SaleGap'" \
                "    AND jei.account_id = CASE WHEN gi.amount >= 0 THEN #{other_usual_running_profits_id} ELSE #{other_usual_running_expenses_id} END" \
                '    AND ((gi.amount < 0 AND jei.real_credit = -gi.pretax_amount)' \
                '      OR (gi.amount >= 0 AND jei.real_debit = gi.pretax_amount))'

        execute 'UPDATE journal_entry_items AS jei' \
                " SET resource_prism = 'client'" \
                '  FROM' \
                '    journal_entries AS je' \
                '    JOIN gaps AS g ON g.journal_entry_id = je.id' \
                '    JOIN entities AS e ON g.entity_id = e.id' \
                "  WHERE je.id = jei.entry_id AND g.type = 'SaleGap'" \
                '    AND jei.account_id = e.client_account_id'

        execute "UPDATE journal_entries AS je SET resource_prism = 'sale_gap' FROM gaps AS g WHERE resource_type = 'Gap' AND resource_id = g.id AND g.type = 'SaleGap' AND je.id IN (SELECT entry_id FROM journal_entry_items WHERE resource_prism IN ('client', 'item_product', 'item_tax'))"

        # tax_declaration

        # Add missing null tax items for sales
        execute 'INSERT INTO journal_entry_items' \
                '   (entry_id, journal_id, financial_year_id, state,' \
                '    printed_on, entry_number, position, account_id, name,' \
                '    real_debit, real_credit, real_balance, real_currency, real_currency_rate,' \
                '    debit, credit, balance, currency,' \
                '    absolute_debit, absolute_credit, absolute_currency, cumulated_absolute_debit, cumulated_absolute_credit,' \
                '    updater_id, created_at, updated_at, creator_id,' \
                '    tax_id, real_pretax_amount, resource_prism, resource_type, resource_id)' \
                '  SELECT je.id, je.journal_id, je.financial_year_id, je.state,' \
                '    je.printed_on, je.number, je.id, t.collect_account_id, \'Null tax\',' \
                '    0, 0, 0, je.real_currency, je.real_currency_rate,' \
                '    0, 0, 0, je.currency,' \
                '    0, 0, je.absolute_currency, 0, 0,' \
                '    je.updater_id, je.created_at, je.updated_at, je.creator_id,' \
                '    t.id, si.pretax_amount, \'item_tax\', \'SaleItem\', si.id' \
                '  FROM sale_items AS si' \
                '    JOIN sales AS s ON si.sale_id = s.id' \
                '    JOIN journal_entries AS je ON s.journal_entry_id = je.id' \
                '    JOIN taxes AS t ON si.tax_id = t.id' \
                '  WHERE si.amount = si.pretax_amount' \
                '    AND si.amount <> 0 AND t.collect_account_id IS NOT NULL'

        # Add missing null tax items for purchases
        execute 'INSERT INTO journal_entry_items' \
                '   (entry_id, journal_id, financial_year_id, state,' \
                '    printed_on, entry_number, position, account_id, name,' \
                '    real_debit, real_credit, real_balance, real_currency, real_currency_rate,' \
                '    debit, credit, balance, currency,' \
                '    absolute_debit, absolute_credit, absolute_currency, cumulated_absolute_debit, cumulated_absolute_credit,' \
                '    updater_id, created_at, updated_at, creator_id,' \
                '    tax_id, real_pretax_amount, resource_prism, resource_type, resource_id)' \
                '  SELECT je.id, je.journal_id, je.financial_year_id, je.state,' \
                '    je.printed_on, je.number, je.id, CASE WHEN fixed THEN t.fixed_asset_deduction_account_id ELSE t.deduction_account_id END, \'Null tax\',' \
                '    0, 0, 0, je.real_currency, je.real_currency_rate,' \
                '    0, 0, 0, je.currency,' \
                '    0, 0, je.absolute_currency, 0, 0,' \
                '    je.updater_id, je.created_at, je.updated_at, je.creator_id,' \
                '    t.id, pi.pretax_amount, \'item_tax\', \'PurchaseItem\', pi.id' \
                '  FROM purchase_items AS pi' \
                '    JOIN purchases AS p ON pi.purchase_id = p.id' \
                '    JOIN journal_entries AS je ON p.journal_entry_id = je.id' \
                '    JOIN taxes AS t ON pi.tax_id = t.id' \
                '  WHERE pi.amount = pi.pretax_amount' \
                '    AND pi.amount <> 0 AND CASE WHEN fixed THEN t.fixed_asset_deduction_account_id ELSE t.deduction_account_id END IS NOT NULL'

        # Add missing null tax items for profit gaps
        execute 'INSERT INTO journal_entry_items' \
                '   (entry_id, journal_id, financial_year_id, state,' \
                '    printed_on, entry_number, position, account_id, name,' \
                '    real_debit, real_credit, real_balance, real_currency, real_currency_rate,' \
                '    debit, credit, balance, currency,' \
                '    absolute_debit, absolute_credit, absolute_currency, cumulated_absolute_debit, cumulated_absolute_credit,' \
                '    updater_id, created_at, updated_at, creator_id,' \
                '    tax_id, real_pretax_amount, resource_prism, resource_type, resource_id)' \
                '  SELECT je.id, je.journal_id, je.financial_year_id, je.state,' \
                "    je.printed_on, je.number, je.id, CASE WHEN direction = 'profit' THEN t.collect_account_id ELSE t.deduction_account_id END, 'Null tax'," \
                '    0, 0, 0, je.real_currency, je.real_currency_rate,' \
                '    0, 0, 0, je.currency,' \
                '    0, 0, je.absolute_currency, 0, 0,' \
                '    je.updater_id, je.created_at, je.updated_at, je.creator_id,' \
                '    t.id, gi.pretax_amount, \'item_tax\', \'GapItem\', gi.id' \
                '  FROM gap_items AS gi' \
                '    JOIN gaps AS p ON gi.gap_id = p.id' \
                '    JOIN journal_entries AS je ON p.journal_entry_id = je.id' \
                '    JOIN taxes AS t ON gi.tax_id = t.id' \
                '  WHERE gi.amount = gi.pretax_amount' \
                "    AND gi.amount <> 0 AND CASE WHEN direction = 'profit' THEN t.collect_account_id ELSE t.deduction_account_id END IS NOT NULL"

        # Updates conversion
        execute 'UPDATE journal_entry_items AS jei SET pretax_amount = real_pretax_amount * real_currency_rate WHERE tax_id IS NOT NULL'
        execute 'UPDATE journal_entry_items AS jei SET absolute_pretax_amount = CASE WHEN absolute_currency = real_currency THEN real_pretax_amount WHEN absolute_currency = currency THEN pretax_amount END WHERE tax_id IS NOT NULL'
      end
    end
  end
end
