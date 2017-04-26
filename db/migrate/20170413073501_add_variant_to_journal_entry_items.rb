class AddVariantToJournalEntryItems < ActiveRecord::Migration
  def up
    add_reference :journal_entry_items, :variant, references: :product_nature_variants, index: true
    add_foreign_key :journal_entry_items, :product_nature_variants, column: :variant_id

    # Historic resumption of journal entries items
    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = p.id, resource_prism = 'stock'" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '    JOIN product_nature_categories AS pnc ON pnv.category_id = pnc.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnc.stock_account_id' \
            "    AND p.nature = 'incoming'" \
            '    AND (pi.pretax_amount >= 0 AND jei.real_debit = pi.pretax_amount)'

    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = p.id, resource_prism = 'stock'" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '    JOIN product_nature_categories AS pnc ON pnv.category_id = pnc.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnc.stock_account_id' \
            "    AND p.nature = 'outgoing'" \
            '    AND (pi.pretax_amount < 0 AND jei.real_credit = -pi.pretax_amount)'

    # Update jei entries without account_id
    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = p.id, resource_prism = 'stock'" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '    JOIN product_nature_categories AS pnc ON pnv.category_id = pnc.id' \
            '  WHERE je.id = jei.entry_id' \
            "    AND p.nature = 'incoming'" \
            '    AND (pi.pretax_amount >= 0 AND jei.real_debit = pi.pretax_amount)'

    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'ParcelItem', resource_id = p.id, resource_prism = 'stock'" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '    JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON pi.variant_id = pnv.id' \
            '    JOIN product_nature_categories AS pnc ON pnv.category_id = pnc.id' \
            '  WHERE je.id = jei.entry_id' \
            "    AND p.nature = 'outgoing'" \
            '    AND (pi.pretax_amount < 0 AND jei.real_credit = -pi.pretax_amount)'

    execute 'UPDATE journal_entry_items AS jei' \
            " SET resource_type = 'InventoryItem', resource_id = i.id, resource_prism = 'stock'" \
            '  FROM' \
            '    journal_entries AS je' \
            '    JOIN inventories AS i ON i.journal_entry_id = je.id' \
            '    JOIN inventory_items AS ii ON ii.inventory_id = i.id' \
            '    JOIN products AS p ON ii.product_id = p.id' \
            '    JOIN product_nature_variants AS pnv ON p.variant_id = pnv.id' \
            '    JOIN product_nature_categories AS pnc ON pnv.category_id = pnc.id' \
            '  WHERE je.id = jei.entry_id' \
            '    AND jei.account_id = pnc.stock_account_id' \
            '    AND (((ii.actual_population * ii.unit_pretax_stock_amount) < 0 AND jei.real_credit = -(ii.actual_population * ii.unit_pretax_stock_amount))' \
            '    OR ((ii.actual_population * ii.unit_pretax_stock_amount) >= 0 AND jei.real_debit = (ii.actual_population * ii.unit_pretax_stock_amount)))'

    #  historic resumption
    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = pi.variant_id' \
            ' FROM' \
            '   purchase_items AS pi' \
            '   JOIN product_nature_variants AS pnc ON pi.variant_id = pnc.id' \
            " WHERE jei.resource_type = 'PurchaseItem'" \
            ' AND jei.resource_id = pi.id' \


    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = si.variant_id' \
            ' FROM' \
            '   sale_items AS si' \
            '   JOIN product_nature_variants AS pnc ON si.variant_id = pnc.id' \
            " WHERE jei.resource_type = 'SaleItem'" \
            ' AND jei.resource_id = si.id' \


    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = p.variant_id' \
            ' FROM' \
            '   inventory_items AS ii' \
            '   JOIN products AS p ON ii.product_id = p.id' \
            '   JOIN product_nature_variants AS pnc ON p.variant_id = pnc.id' \
            " WHERE jei.resource_type = 'InventoryItem'" \
            ' AND jei.resource_id = ii.id' \

    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = pi.variant_id' \
            ' FROM' \
            '   parcel_items AS pi' \
            '   JOIN product_nature_variants AS pnc ON pi.variant_id = pnc.id' \
            " WHERE jei.resource_type = 'ParcelItem'" \
            ' AND jei.resource_id = pi.id' \
  end

  def down; end
end
