class AddVariantToJournalEntryItems < ActiveRecord::Migration
  def up
    add_reference :journal_entry_items, :variant, references: :product_nature_variants, index: true
    add_foreign_key :journal_entry_items, :product_nature_variants, column: :variant_id

    #  historic resumption
    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = pi.variant_id' \
            ' FROM' \
            '   journal_entries AS je' \
            '   JOIN purchases AS p ON p.journal_entry_id = je.id' \
            '   JOIN purchase_items AS pi ON pi.purchase_id = p.id' \
            ' WHERE je.id = jei.entry_id' \
            ' AND pi.account_id = jei.account_id' \


    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = si.variant_id' \
            ' FROM' \
            '   journal_entries AS je' \
            '   JOIN sales AS s ON s.journal_entry_id = je.id' \
            '   JOIN sale_items AS si ON si.sale_id = s.id' \
            ' WHERE je.id = jei.entry_id' \
            ' AND si.account_id = jei.account_id' \


    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = p.variant_id' \
            ' FROM' \
            '   journal_entries AS je' \
            '   JOIN inventories AS i ON i.journal_entry_id = je.id' \
            '   JOIN inventory_items AS ii ON ii.inventory_id = i.id' \
            '   JOIN products AS p ON p.id = ii.product_id' \
            ' WHERE je.id = jei.entry_id' \

    execute 'UPDATE journal_entry_items AS jei' \
            ' SET variant_id = pi.variant_id' \
            ' FROM' \
            '   journal_entries AS je' \
            '   JOIN parcels AS p ON p.journal_entry_id = je.id' \
            '   JOIN parcel_items AS pi ON pi.parcel_id = p.id' \
            ' WHERE je.id = jei.entry_id' \
  end

  def down; end
end
