class AddTaxesInJournals < ActiveRecord::Migration
  def change
    add_reference :journal_entry_items, :tax, index: true
    add_column :journal_entry_items, :pretax_amount, :decimal,
               precision: 19, scale: 4, null: false, default: 0.0
    add_column :journal_entry_items, :real_pretax_amount, :decimal,
               precision: 19, scale: 4, null: false, default: 0.0
    add_column :journal_entry_items, :absolute_pretax_amount,
               :decimal, precision: 19, scale: 4, null: false, default: 0.0

    # Recover historic when possible
    reversible do |d|
      d.up do
        # From sales
        execute 'UPDATE journal_entry_items AS jei SET tax_id = t.id, real_pretax_amount = si.pretax_amount' \
                ' FROM sale_items AS si JOIN sales AS s ON (si.sale_id = s.id) JOIN journal_entries AS je ON (s.journal_entry_id = je.id) JOIN taxes AS t ON (t.id = si.tax_id)' \
                ' WHERE je.id = jei.entry_id AND t.collect_account_id = jei.account_id AND (si.amount - si.pretax_amount) = jei.real_credit'
        # From purchases
        execute 'UPDATE journal_entry_items AS jei SET tax_id = t.id, real_pretax_amount = pi.pretax_amount' \
                ' FROM purchase_items AS pi JOIN purchases AS p ON (pi.purchase_id = p.id) JOIN journal_entries AS je ON (p.journal_entry_id = je.id) JOIN taxes AS t ON (t.id = pi.tax_id)' \
                ' WHERE NOT pi.fixed AND je.id = jei.entry_id AND t.deduction_account_id = jei.account_id AND (pi.amount - pi.pretax_amount) = jei.real_credit'
        execute 'UPDATE journal_entry_items AS jei SET tax_id = t.id, real_pretax_amount = pi.pretax_amount' \
                ' FROM purchase_items AS pi JOIN purchases AS p ON (pi.purchase_id = p.id) JOIN journal_entries AS je ON (p.journal_entry_id = je.id) JOIN taxes AS t ON (t.id = pi.tax_id)' \
                ' WHERE pi.fixed AND je.id = jei.entry_id AND t.fixed_asset_deduction_account_id = jei.account_id AND (pi.amount - pi.pretax_amount) = jei.real_credit'
        # Updates conversion
        execute 'UPDATE journal_entry_items AS jei SET pretax_amount = real_pretax_amount * real_currency_rate WHERE tax_id IS NOT NULL'
        execute 'UPDATE journal_entry_items AS jei SET absolute_pretax_amount = CASE WHEN absolute_currency = real_currency THEN real_pretax_amount WHEN absolute_currency = currency THEN pretax_amount END WHERE tax_id IS NOT NULL'
      end
    end
  end
end
