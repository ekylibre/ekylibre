class AddVariantToJournalEntryItems < ActiveRecord::Migration
  def up
    add_reference :journal_entry_items, :variant, index: true
    add_foreign_key :journal_entry_items, :product_nature_variants, column: :variant_id

    link_variants_for_permanent_stock_inventory_in_parcels

    link_variants_for_undelivered_invoice_in_parcels

    # INFO: Don't know how to link stock(_movement)_reset

    link_variants_for_inventory_stocks

    # Historic resumption
    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = pi.variant_id' \
            ' FROM' \
            '   purchase_items AS pi' \
            '   JOIN product_nature_variants AS pnv ON pnv.id = pi.variant_id' \
            " WHERE jei.resource_type = 'PurchaseItem'" \
            ' AND jei.resource_id = pi.id' \
            ' AND jei.variant_id IS NULL'

    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = si.variant_id' \
            ' FROM' \
            '   sale_items AS si' \
            '   JOIN product_nature_variants AS pnv ON pnv.id = si.variant_id' \
            " WHERE jei.resource_type = 'SaleItem'" \
            ' AND jei.resource_id = si.id' \
            ' AND jei.variant_id IS NULL'
  end

  def down
    remove_reference :journal_entry_items, :variant
  end

  def link_variants_for_permanent_stock_inventory_in_parcels
    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = pi.id, resource_prism = 'stock', variant_id = pi.variant_id" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnv.stock_account_id' \
            "    AND ((p.nature = 'incoming' AND (pi.population * pi.unit_pretax_stock_amount) = (jei.real_debit - jei.real_credit))" \
            "      OR (p.nature = 'outgoing' AND (pi.population * pi.unit_pretax_stock_amount) = (jei.real_credit - jei.real_debit)))"

    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = pi.id, resource_prism = 'stock_movement', variant_id = pi.variant_id" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnv.stock_movement_account_id' \
            "    AND ((p.nature = 'incoming' AND (pi.population * pi.unit_pretax_stock_amount) = (jei.real_credit - jei.real_debit))" \
            "      OR (p.nature = 'outgoing' AND (pi.population * pi.unit_pretax_stock_amount) = (jei.real_debit - jei.real_credit)))"
  end

  def link_variants_for_undelivered_invoice_in_parcels
    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = pi.id, resource_prism = 'unbilled', variant_id = pi.variant_id" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            "    JOIN accounts AS a ON (a.usages = CASE WHEN p.nature = 'incoming' THEN 'suppliers_invoices_not_received' ELSE 'invoice_to_create_clients' END)" \
            '    LEFT JOIN sale_items AS tsi ON pi.sale_item_id = tsi.id' \
            '    LEFT JOIN purchase_items AS tpi ON pi.purchase_item_id = tpi.id' \
            '  WHERE je.id = jei.entry_id AND jei.account_id = a.id' \
            "    AND ((p.nature = 'incoming' AND COALESCE(tsi.pretax_amount, tpi.pretax_amount, pi.population * pi.unit_pretax_stock_amount) = (jei.real_credit - jei.real_debit))" \
            "      OR (p.nature = 'outgoing' AND COALESCE(tsi.pretax_amount, tpi.pretax_amount, pi.population * pi.unit_pretax_stock_amount) = (jei.real_debit - jei.real_credit)))"

    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = pi.id, resource_prism = 'expense', variant_id = pi.variant_id" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '    JOIN product_nature_categories AS pnc ON pnv.category_id = pnc.id' \
            '    LEFT JOIN sale_items AS tsi ON pi.sale_item_id = tsi.id' \
            '    LEFT JOIN purchase_items AS tpi ON pi.purchase_item_id = tpi.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnc.charge_account_id' \
            "    AND ((p.nature = 'incoming' AND COALESCE(tsi.pretax_amount, tpi.pretax_amount, pi.population * pi.unit_pretax_stock_amount) = (jei.real_debit - jei.real_credit))" \
            "      OR (p.nature = 'outgoing' AND COALESCE(tsi.pretax_amount, tpi.pretax_amount, pi.population * pi.unit_pretax_stock_amount) = (jei.real_credit - jei.real_debit)))"
  end

  def link_variants_for_inventory_stocks
    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ProductNatureVariant', resource_id = v.variant_id, resource_prism = 'stock', variant_id = v.variant_id" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN inventories AS i ON i.journal_entry_id = je.id' \
            '    JOIN (SELECT ii.inventory_id, p.variant_id, SUM(ii.actual_population * ii.unit_pretax_stock_amount) AS stock_amount FROM inventory_items AS ii JOIN products AS p ON ii.product_id = p.id GROUP BY 1, 2) AS v ON v.inventory_id = i.id' \
            '    JOIN product_nature_variants AS pnv ON v.variant_id = pnv.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnv.stock_movement_account_id' \
            '    AND ((v.stock_amount >= 0 AND jei.real_credit = v.stock_amount)' \
            '    OR (stock_amount < 0 AND jei.real_debit = -1 * v.stock_amount))'

    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ProductNatureVariant', resource_id = v.variant_id, resource_prism = 'stock_movement', variant_id = v.variant_id" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN inventories AS i ON i.journal_entry_id = je.id' \
            '    JOIN (SELECT ii.inventory_id, p.variant_id, SUM(ii.actual_population * ii.unit_pretax_stock_amount) AS stock_amount FROM inventory_items AS ii JOIN products AS p ON ii.product_id = p.id GROUP BY 1, 2) AS v ON v.inventory_id = i.id' \
            '    JOIN product_nature_variants AS pnv ON v.variant_id = pnv.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnv.stock_account_id' \
            '    AND ((v.stock_amount >= 0 AND jei.real_debit = v.stock_amount)' \
            '    OR (stock_amount < 0 AND jei.real_credit = -1 * v.stock_amount))'
  end
end
