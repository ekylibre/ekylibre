class NormalizeTaxesUses < ActiveRecord::Migration
  def change
    # CatalogPrice/Item
    rename_table :catalog_prices, :catalog_items
    # Removes old items
    execute 'DELETE FROM catalog_items WHERE stopped_at IS NOT NULL'
    # Removes old duplicates
    execute 'DELETE FROM catalog_items WHERE id NOT IN (SELECT p.id FROM (SELECT ci.id, ROW_NUMBER() OVER(PARTITION BY ci.catalog_id, ci.variant_id ORDER BY ci.id DESC) AS rank FROM catalog_items AS ci) AS p WHERE p.rank = 1)'
    add_index :catalog_items, %i[catalog_id variant_id], unique: true
    add_column :catalog_items, :commercial_description, :text
    add_column :catalog_items, :commercial_name, :string
    execute 'UPDATE catalog_items SET name = variants.commercial_name, commercial_name = CASE WHEN variants.name = variants.commercial_name THEN NULL ELSE variants.commercial_name END, commercial_description = variants.commercial_description FROM product_nature_variants AS variants WHERE variants.id = variant_id'
    remove_column :product_nature_variants, :commercial_name
    remove_column :product_nature_variants, :commercial_description
    remove_column :catalog_items, :thread
    remove_column :catalog_items, :started_at
    remove_column :catalog_items, :stopped_at
    remove_column :catalog_items, :indicator_name

    # Sale
    rename_column :sale_items, :unit_price_amount, :unit_pretax_amount
    add_column :sale_items, :unit_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    execute 'UPDATE sale_items SET unit_amount = unit_pretax_amount * (100 + taxes.amount) / 100 FROM taxes WHERE taxes.id = tax_id'
    add_column :sale_items, :reduced_unit_pretax_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    add_column :sale_items, :reduced_unit_amount,        :decimal, precision: 19, scale: 4, default: 0.0, null: false
    execute 'UPDATE sale_items SET reduced_unit_pretax_amount = unit_pretax_amount * (100 - reduction_percentage) / 100, reduced_unit_amount = unit_amount * (100 - reduction_percentage) / 100'
    add_column :sale_items, :all_taxes_included, :boolean, null: false, default: false
    execute 'DELETE FROM sale_items WHERE reduced_item_id IS NOT NULL'
    remove_column :sale_items, :reduced_item_id
    remove_column :sale_items, :price_id

    add_column :sales, :reduction_percentage,       :decimal, precision: 19, scale: 4, default: 0.0, null: false
    add_column :sales, :prereduction_amount,        :decimal, precision: 19, scale: 4, default: 0.0, null: false
    add_column :sales, :prereduction_pretax_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    execute 'UPDATE sales SET prereduction_amount = amount, prereduction_pretax_amount = pretax_amount'
    rename_column :sales, :origin_id, :credited_sale_id
    remove_column :sale_items, :indicator_name

    # Purchase
    rename_column :purchase_items, :unit_price_amount, :unit_pretax_amount
    add_column :purchase_items, :unit_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    execute 'UPDATE purchase_items SET unit_amount = unit_pretax_amount * (100 + taxes.amount) / 100 FROM taxes WHERE taxes.id = tax_id'
    add_column :purchase_items, :all_taxes_included, :boolean, null: false, default: false
    remove_column :purchase_items, :indicator_name
  end
end
