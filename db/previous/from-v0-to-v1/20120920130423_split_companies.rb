class SplitCompanies < ActiveRecord::Migration
  def up

    # Upgrade sequence to integrate directly usage
    add_column :sequences, :usage, :string
    execute "UPDATE #{quoted_table_name(:sequences)} SET usage = REPLACE(p.name, '_sequence', '') FROM #{quoted_table_name(:preferences)} AS p WHERE record_value_id = #{quoted_table_name(:sequences)}.id AND record_value_type = 'Sequence'"
    execute "DELETE FROM #{quoted_table_name(:preferences)} WHERE record_value_type = 'Sequence'"

    # Ensure sale_nature has journal if with accounting
    if connection.select_value("SELECT count(*) FROM #{quoted_table_name(:sale_natures)} AS sn LEFT JOIN #{quoted_table_name(:journals)} AS j ON (journal_id = j.id) WHERE sn.with_accounting AND j.name IS NULL").to_i > 0
      raise Exception.new("SaleNature#journal must be filled before migrating")
    end

    add_column :incoming_payment_modes, :detail_payments, :boolean, :null => false, :default => false
    execute "UPDATE #{quoted_table_name(:incoming_payment_modes)} SET detail_payments = #{quoted_true}"
    add_column :incoming_payment_modes, :attorney_journal_id, :integer
    execute "UPDATE #{quoted_table_name(:incoming_payment_modes)} SET attorney_journal_id = j.id FROM #{quoted_table_name(:journals)} AS j WHERE j.nature = 'various' AND j.company_id = #{quoted_table_name(:incoming_payment_modes)}.company_id"
    add_column :outgoing_payment_modes, :attorney_journal_id, :integer
    execute "UPDATE #{quoted_table_name(:outgoing_payment_modes)} SET attorney_journal_id = j.id FROM #{quoted_table_name(:journals)} AS j WHERE j.nature = 'various' AND j.company_id = #{quoted_table_name(:outgoing_payment_modes)}.company_id"

    # Set currency in entities
    add_column :entities, :currency, :string, :limit => 3
    execute "UPDATE #{quoted_table_name(:entities)} SET currency = c.currency FROM #{quoted_table_name(:companies)} AS c WHERE c.id = #{quoted_table_name(:entities)}.company_id"
    change_column_null :entities, :currency, false

    # Defines explicitly in entities which entity is this of the company
    add_column :entities, :of_company, :boolean, :null => false, :default => false
    add_index :entities, :of_company
    execute "UPDATE #{quoted_table_name(:entities)} SET of_company = #{quoted_true} WHERE id IN (SELECT entity_id FROM #{quoted_table_name(:companies)})"

    # Move sales_conditions in SaleNature
    add_column :sale_natures, :sales_conditions, :text
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET sales_conditions = c.sales_conditions FROM #{quoted_table_name(:companies)} AS c WHERE c.id = #{quoted_table_name(:sale_natures)}.company_id"

    # TODO: Reorganize account preferences


    # Data separation
    schema_tables = [:account_balances, :accounts, :areas, :asset_depreciations, :assets, :bank_statements, :cash_transfers, :cashes, :contacts, :cultivations, :custom_field_choices, :custom_field_data, :custom_fields, :delays, :departments, :deposit_lines, :deposits, :districts, :document_templates, :documents, :entities, :entity_categories, :entity_link_natures, :entity_links, :entity_natures, :establishments, :event_natures, :events, :financial_years, :incoming_deliveries, :incoming_delivery_lines, :incoming_delivery_modes, :incoming_payment_modes, :incoming_payment_uses, :incoming_payments, :inventories, :inventory_lines, :journal_entries, :journal_entry_lines, :journals, :land_parcel_groups, :land_parcel_kinships, :land_parcels, :listing_node_items, :listing_nodes, :listings, :mandates, :observations, :operation_lines, :operation_natures, :operation_uses, :operations, :outgoing_deliveries, :outgoing_delivery_lines, :outgoing_delivery_modes, :outgoing_payment_modes, :outgoing_payment_uses, :outgoing_payments, :preferences, :prices, :product_categories, :product_components, :production_chain_conveyors, :production_chain_work_center_uses, :production_chain_work_centers, :production_chains, :products, :professions, :purchase_lines, :purchase_natures, :purchases, :roles, :sale_lines, :sale_natures, :sales, :sequences, :sessions, :stock_moves, :stock_transfers, :stocks, :subscription_natures, :subscriptions, :tax_declarations, :taxes, :tools, :tracking_states, :trackings, :transfers, :transports, :units, :users, :warehouses]

    companies = connection.select_all("SELECT * FROM #{quoted_table_name(:companies)}").inject([]) do |array, company|
      array << [company["code"].ascii.downcase, company["id"].to_i]
    end

    schema_indexes = schema_tables.inject({}) do |hash, table|
      hash[table.to_sym] = indexes(table).inject({}) do |hi, index|
        columns = index.columns.delete_if{|c| c.to_sym == :company_id}
        hi[index.name] = {:columns => columns.join(', '), :unique => index.unique} unless columns.empty?
        hi
      end
      hash
    end


    for schema, id in companies
      execute "CREATE SCHEMA #{schema}"
      for table in schema_tables
        if table != :sessions
          execute "CREATE TABLE #{schema}.#{table} AS SELECT * FROM #{table} WHERE company_id = #{id}"
          execute "ALTER TABLE #{schema}.#{table} DROP COLUMN company_id"
          execute "DELETE FROM #{table} WHERE company_id = #{id}"
        else
          execute "CREATE TABLE #{schema}.#{table} AS SELECT * FROM #{table}"
          execute "DELETE FROM #{schema}.#{table}"
        end
        execute "ALTER TABLE #{schema}.#{table} ADD PRIMARY KEY(id)"
        sequence, max = "#{schema}.#{table}_id_seq", connection.select_value("SELECT MAX(id) AS max FROM #{schema}.#{table}")
        execute "CREATE SEQUENCE #{sequence} MINVALUE 1 START WITH #{max.to_i + 1} OWNED BY #{schema}.#{table}.id"
        execute "ALTER TABLE #{schema}.#{table} ALTER COLUMN id SET DEFAULT nextval('#{sequence}')"
        for name, index in schema_indexes[table]
          execute "CREATE#{' UNIQUE' if index[:unique]} INDEX #{name} ON #{schema}.#{table} (#{index[:columns]})"
        end
      end
    end

    for table in schema_tables
      remove_column table, :company_id if table != :sessions
    end

    # add_preference = Proc.new do |name, nature = :string, values = nil, columns = nil|
    #   values  ||= name
    #   columns = "#{nature}_value"
    #   if nature == :record
    #     columns = "record_value_id, record_value_type"
    #   end
    #   for schema, id in companies
    #     execute "INSERT INTO #{schema}.#{quoted_table_name(:preferences)} (name, nature, #{columns}) SELECT '#{name}', '#{nature}', #{values} FROM #{quoted_table_name(:companies)} WHERE id = #{id}"
    #   end
    #   remove_column :companies, name
    # end

    # Removes data columns of companies table
    deleted_columns = [:born_on, :locked, :creator_id, :updater_id, :created_at, :updated_at, :lock_version, :currency, :entity_id, :language, :name, :sales_conditions]
    add_column :companies, :log, :text
    execute "UPDATE #{quoted_table_name(:companies)} SET log = E'---\\nbackup:\\n' || "+deleted_columns.collect{|c| "'  #{c}: ' || COALESCE(CAST(#{c} AS VARCHAR), 'NULL')"  }.join(" || E'\\n' || ")
    for column in deleted_columns
      remove_column :companies, column
    end
    # add_preference[:currency] # in entities
    # add_preference[:entity_id, :record, "entity_id, 'Entity'"] # in entities
    # add_preference[:language] # in entities
    # add_preference[:name] # in entities
    # add_preference[:sales_conditions] # in sale_natures

  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
