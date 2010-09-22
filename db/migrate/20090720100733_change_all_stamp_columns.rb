class ChangeAllStampColumns < ActiveRecord::Migration

  # ALL_EXISTING_TABLES = [:schema_migrations, :sessions, :companies, :languages, :users, :templates, :roles, :parameters, :documents, :establishments, :departments, :entity_natures, :address_norms, :address_norm_items, :complements, :complement_data, :currencies, :complement_choices, :accounts, :financialyears, :account_balances, :journals, :bank_account_statements, :entries, :journal_records, :units, :shelves, :products, :taxes, :price_taxes, :stock_trackings, :stock_moves, :stock_locations, :delays, :sale_order_natures, :sale_orders, :sale_order_lines, :delivery_lines, :purchase_orders, :purchase_order_lines, :payment_modes, :payment_parts, :prices, :professions, :employees, :contacts, :bank_accounts, :product_stocks, :entities, :shapes, :product_components, :productions, :shape_operations, :payments, :shape_operation_natures, :meeting_locations, :meeting_modes, :meetings, :stock_transfers, :inventories, :inventory_lines, :delivery_modes, :deliveries, :entity_categories, :invoice_lines, :invoices, :embankments, :districts, :cities, :areas, :subscription_natures, :subscriptions, :sequences]

  EXISTING_TABLES = [:companies, :languages, :users, :templates, :roles, :parameters, :documents, :establishments, :departments, :entity_natures, :address_norms, :address_norm_items, :complements, :complement_data, :currencies, :complement_choices, :accounts, :financialyears, :account_balances, :journals, :bank_account_statements, :entries, :journal_records, :units, :shelves, :products, :taxes, :price_taxes, :stock_trackings, :stock_moves, :stock_locations, :delays, :sale_order_natures, :sale_orders, :sale_order_lines, :delivery_lines, :purchase_orders, :purchase_order_lines, :payment_modes, :payment_parts, :prices, :professions, :employees, :contacts, :bank_accounts, :product_stocks, :entities, :shapes, :product_components, :productions, :shape_operations, :payments, :shape_operation_natures, :meeting_locations, :meeting_modes, :meetings, :stock_transfers, :inventories, :inventory_lines, :delivery_modes, :deliveries, :entity_categories, :invoice_lines, :invoices, :embankments, :districts, :cities, :areas, :subscription_natures, :subscriptions, :sequences]

  def self.up
    for table in EXISTING_TABLES
      columns = columns(table).collect{|c| c.name.to_sym}
      add_column table, :creator_id, :integer unless columns.include? :creator_id
      add_column table, :updater_id, :integer unless columns.include? :updater_id
      execute "UPDATE #{quote_table_name(table)} SET creator_id=created_by" if columns.include?(:creator_id) and columns.include?(:created_by)
      execute "UPDATE #{quote_table_name(table)} SET updater_id=updated_by" if columns.include?(:updater_id) and columns.include?(:updated_by)
      remove_column table, :created_by if columns.include? :created_by
      remove_column table, :updated_by if columns.include? :updated_by
    end

    add_column :languages, :created_at, :timestamp
    add_column :languages, :updated_at, :timestamp
  end

  def self.down
    remove_column :languages, :updated_at
    remove_column :languages, :created_at

    for table in EXISTING_TABLES.reverse
      columns = columns(table).collect{|c| c.name.to_sym}
      add_column table, :updated_by, :integer unless columns.include? :updated_by
      add_column table, :created_by, :integer unless columns.include? :created_by
      execute "UPDATE #{quote_table_name(table)} SET updated_by=updater_id" if columns.include?(:updater_id) and columns.include?(:updated_by)
      execute "UPDATE #{quote_table_name(table)} SET created_by=creator_id" if columns.include?(:creator_id) and columns.include?(:created_by)
      remove_column table, :updater_id if columns.include? :updater_id
      remove_column table, :creator_id if columns.include? :creator_id
    end

    remove_column :languages, :updated_by
    remove_column :languages, :created_by
  end

end
