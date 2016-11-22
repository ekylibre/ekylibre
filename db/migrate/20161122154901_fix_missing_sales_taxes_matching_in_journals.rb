class FixMissingSalesTaxesMatchingInJournals < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        # INSERT MISSING NULL TAX FOR SALES
        execute 'INSERT INTO journal_entry_items 
        (entry_id, journal_id, financial_year_id, state, 
        printed_on, entry_number, position, account_id, name, 
        real_debit, real_credit, real_balance, real_currency, real_currency_rate, 
        debit, credit, balance, currency, 
        absolute_debit, absolute_credit, absolute_currency, cumulated_absolute_debit, cumulated_absolute_credit,
        updater_id, created_at, updated_at, creator_id, 
        tax_id, real_pretax_amount)  
        SELECT je.id, je.journal_id, je.financial_year_id, je.state,
        je.printed_on, je.number, je.id, t.collect_account_id, jei.name,
        0, 0, 0, je.real_currency, je.real_currency_rate,
        0, 0, 0, je.currency,
        0, 0, je.absolute_currency, 0, 0,
        je.updater_id, je.created_at, je.updated_at, je.creator_id,
        t.id, si.pretax_amount
        FROM sale_items si
        JOIN product_nature_variants pnv ON si.variant_id = pnv.id
        JOIN product_nature_categories pnc ON pnv.category_id = pnc.id
        JOIN sales s ON si.sale_id = s.id
        JOIN journal_entries je ON s.journal_entry_id = je.id
        JOIN journal_entry_items jei ON jei.entry_id = je.id AND pnc.product_account_id = jei.account_id AND ((si.amount >= 0 AND jei.credit = si.pretax_amount) OR (si.amount < 0 AND jei.debit = -si.pretax_amount)) 
        JOIN taxes t ON si.tax_id = t.id
        WHERE si.amount = si.pretax_amount
        AND si.amount <> 0'
        
        # INSERT MISSING NULL TAX FOR PURCHASES
        execute 'INSERT INTO journal_entry_items 
        (entry_id, journal_id, financial_year_id, state, 
        printed_on, entry_number, position, account_id, name, 
        real_debit, real_credit, real_balance, real_currency, real_currency_rate, 
        debit, credit, balance, currency, 
        absolute_debit, absolute_credit, absolute_currency, cumulated_absolute_debit, cumulated_absolute_credit,
        updater_id, created_at, updated_at, creator_id, 
        tax_id, real_pretax_amount)  
        SELECT je.id, je.journal_id, je.financial_year_id, je.state,
        je.printed_on, je.number, je.id, CASE WHEN fixed THEN t.fixed_asset_deduction_account_id ELSE t.deduction_account_id END, jei.name,
        0, 0, 0, je.real_currency, je.real_currency_rate,
        0, 0, 0, je.currency,
        0, 0, je.absolute_currency, 0, 0,
        je.updater_id, je.created_at, je.updated_at, je.creator_id,
        t.id, si.pretax_amount
        FROM purchase_items si
        JOIN product_nature_variants pnv ON si.variant_id = pnv.id
        JOIN product_nature_categories pnc ON pnv.category_id = pnc.id
        JOIN purchases s ON si.purchase_id = s.id
        JOIN journal_entries je ON s.journal_entry_id = je.id
        JOIN journal_entry_items jei ON jei.entry_id = je.id AND pnc.product_account_id = jei.account_id AND ((si.amount >= 0 AND jei.debit = si.pretax_amount) OR (si.amount < 0 AND jei.credit = -si.pretax_amount)) 
        JOIN taxes t ON si.tax_id = t.id
        WHERE si.amount = si.pretax_amount
        AND si.amount <> 0'
        
        # Updates conversion
        execute 'UPDATE journal_entry_items AS jei SET pretax_amount = real_pretax_amount * real_currency_rate WHERE tax_id IS NOT NULL'
        execute 'UPDATE journal_entry_items AS jei SET absolute_pretax_amount = CASE WHEN absolute_currency = real_currency THEN real_pretax_amount WHEN absolute_currency = currency THEN pretax_amount END WHERE tax_id IS NOT NULL'
      end
    end
  end
end
