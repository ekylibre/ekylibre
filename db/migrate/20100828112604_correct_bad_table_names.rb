class CorrectBadTableNames < ActiveRecord::Migration
  WAREHOUSE_REFS = [:sale_delivery_lines, :inventory_lines, :invoice_lines, :operation_lines, :product_components, :purchase_order_lines, :sale_order_lines, :stocks, :stock_moves, :stock_transfers]
  RECORD_REFS = [:deposits, :inventories, :invoices, :purchase_orders, :purchase_payments, :purchase_payment_parts, :sale_orders, :sale_payments, :sale_payment_parts, :tax_declarations, :transfers]
  YEAR_REFS = [:account_balances, :tax_declarations]
  RIGHTS_UPDATES = {
    "manage_complements"    => "manage_custom_fields",
    "manage_delivery_modes" => "manage_sale_delivery_modes",
    "manage_embankments"    => "manage_deposits",
    "manage_entries"        => "manage_journal_entries",
    "manage_financialyears" => "manage_financial_years",
    "manage_locations"      => "manage_warehouse",
    "manage_shapes"         => "manage_land_parcels",
    "manage_shelves"        => "manage_product_categories"
  }.to_a.sort
  TABLES_UPDATES = {
    :delivery_modes        => :sale_delivery_modes,
    :delivery_lines        => :sale_delivery_lines,
    :deliveries            => :sale_deliveries,
    :complements           => :custom_fields,
    :complement_choices    => :custom_field_choices,
    :complement_data       => :custom_field_data,
    :embankments           => :deposits,
    :financialyears        => :financial_years,
    :journal_entries       => :journal_entry_lines,
    :journal_records       => :journal_entries,
    :locations             => :warehouses,
    :parameters            => :preferences,
    :shapes                => :land_parcels,
    :shelves               => :product_categories
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  

  def self.up
    for old, new in TABLES_UPDATES
      rename_table old, quote_table_name(new)
    end

    rename_column :custom_field_choices, :complement_id, :custom_field_id
    rename_column :custom_field_data, :complement_id, :custom_field_id
    
    rename_column :sale_payments, :embankment_id, :deposit_id
    rename_column :sale_payments, :embanker_id, :responsible_id
    rename_column :sale_payment_modes, :with_embankment, :with_deposit
    rename_column :sale_payment_modes, :embankables_account_id, :depositables_account_id
    rename_column :deposits, :embanker_id, :responsible_id
    

    # http://en.wikipedia.org/wiki/Legal_entity
    # No changes on entity

    for table in YEAR_REFS
      columns = columns(table).collect{|c| c.name.to_sym}
      rename_column(table, :financialyear_id, :financial_year_id)
    end

    rename_column :journal_entry_lines, :record_id, :entry_id
    for table in RECORD_REFS
      columns = columns(table).collect{|c| c.name.to_sym}
      rename_column(table, :journal_record_id, :journal_entry_id)
    end
    
    for table in WAREHOUSE_REFS
      columns = columns(table).collect{|c| c.name.to_sym}
      rename_column(table, :location_id, :warehouse_id)
      rename_column(table, :second_location_id, :second_warehouse_id) if columns.include?(:second_location_id)
    end
    
    rename_column :products, :shelf_id, :category_id

    # UPDATE RIGHTS
    for old, new in RIGHTS_UPDATES
      execute "UPDATE #{quote_table_name(:users)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
      execute "UPDATE #{quote_table_name(:roles)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
    end

    # UPDATE DOCUMENT_TEMPLATES
    execute "UPDATE #{quote_table_name(:document_templates)} SET nature='deposit' WHERE nature='embankment'"

    # UPDATE LISTINGS
    for old, new in TABLES_UPDATES
      execute "UPDATE #{quote_table_name(:listing_nodes)} SET attribute_name = '#{new.to_s.singularize}' WHERE attribute_name = '#{old.to_s.singularize}'"
      execute "UPDATE #{quote_table_name(:listing_nodes)} SET attribute_name = '#{new}' WHERE attribute_name = '#{old}'"
    end

    # UPDATE PREFERENCES
    execute "UPDATE #{quote_table_name(:preferences)} SET name = REPLACE(name, 'embankments', 'deposits')"
    execute "UPDATE #{quote_table_name(:preferences)} SET name = REPLACE(name, 'to_embank', 'to_deposit')"

    # UPDATE POLYMORHIC REFERENCES
    execute "UPDATE #{quote_table_name(:operations)} SET target_type='LandParcel' WHERE target_type='Shape'"
  end

  # UPDATE LOCALES

  def self.down
    # UPDATE POLYMORHIC REFERENCES
    execute "UPDATE #{quote_table_name(:operations)} SET target_type='Shape' WHERE target_type='LandParcel'"

    # UPDATE PREFERENCES
    execute "UPDATE #{quote_table_name(:preferences)} SET name = REPLACE(name, 'to_deposit', 'to_embank')"
    execute "UPDATE #{quote_table_name(:preferences)} SET name = REPLACE(name, 'deposits', 'embankments')"

    # UPDATE LISTINGS
    for new, old in TABLES_UPDATES.reverse
      execute "UPDATE #{quote_table_name(:listing_nodes)} SET attribute_name = '#{new}' WHERE attribute_name = '#{old}'"
      execute "UPDATE #{quote_table_name(:listing_nodes)} SET attribute_name = '#{new.to_s.singularize}' WHERE attribute_name = '#{old.to_s.singularize}'"
    end

    # UPDATE DOCUMENT_TEMPLATES
    execute "UPDATE #{quote_table_name(:document_templates)} SET nature='deposit' WHERE nature='embankment'"

    # UPDATE RIGHTS
    for new, old in RIGHTS_UPDATES.reverse
      execute "UPDATE #{quote_table_name(:roles)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
      execute "UPDATE #{quote_table_name(:users)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
    end


    rename_column :products, :category_id, :shelf_id

    for table in WAREHOUSE_REFS.reverse
      columns = columns(table).collect{|c| c.name.to_sym}
      rename_column(table, :second_warehouse_id, :second_location_id) if columns.include?(:second_warehouse_id)
      rename_column(table, :warehouse_id, :location_id)
    end

    for table in RECORD_REFS.reverse
      columns = columns(table).collect{|c| c.name.to_sym}
      rename_column(table, :journal_entry_id, :journal_record_id)
    end
    rename_column :journal_entry_lines, :entry_id, :record_id
  
    for table in YEAR_REFS.reverse
      columns = columns(table).collect{|c| c.name.to_sym}
      rename_column(table, :financial_year_id, :financialyear_id)
    end
    
    # http://en.wikipedia.org/wiki/Legal_entity
    # No changes on entity
    rename_column :deposits, :responsible_id, :embanker_id
    rename_column :sale_payment_modes, :depositables_account_id, :embankables_account_id
    rename_column :sale_payment_modes, :with_deposit, :with_embankment
    rename_column :sale_payments, :responsible_id, :embanker_id
    rename_column :sale_payments, :deposit_id, :embankment_id
    
    rename_column :custom_field_data, :custom_field_id, :complement_id
    rename_column :custom_field_choices, :custom_field_id, :complement_id

    for new, old in TABLES_UPDATES.reverse
      rename_table old, quote_table_name(new)
    end
  end
end
