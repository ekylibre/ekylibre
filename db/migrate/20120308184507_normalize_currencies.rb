class NormalizeCurrencies < ActiveRecord::Migration
  # asset              currency_id            integer                      not-null
  # bank_statement     currency_credit        decimal(16,2)  default(0.0)  not-null
  # bank_statement     currency_debit         decimal(16,2)  default(0.0)  not-null
  # cash               currency_id            integer                      not-null
  # cash_transfer      currency_id            integer
  # cash_transfer      emitter_currency_id    integer                      not-null
  # cash_transfer      emitter_currency_rate  decimal(16,6)  default(1.0)  not-null
  # cash_transfer      receiver_currency_id   integer
  # cash_transfer      receiver_currency_rate decimal(16,6)
  # incoming_delivery  currency_id            integer
  # journal_entry_line currency_credit        decimal(16,2)  default(0.0)  not-null
  # journal_entry_line currency_debit         decimal(16,2)  default(0.0)  not-null
  # journal_entry      currency_credit        decimal(16,2)  default(0.0)  not-null
  # journal_entry      currency_debit         decimal(16,2)  default(0.0)  not-null
  # journal_entry      currency_id            integer        default(0)    not-null
  # journal_entry      currency_rate          decimal(16,6)  default(0.0)  not-null
  # journal            currency_id            integer                      not-null
  # outgoing_delivery  currency_id            integer
  # price              currency_id            integer
  # purchase           currency_id            integer
  # sale               currency_id            integer

  CURRENCIES = {
    :assets => {:currency_id => :currency},
    :cashes => {:currency_id => :currency},
    :cash_transfers => {
      :currency_id => :currency,
      :emitter_currency_id => :emitter_currency,
      :receiver_currency_id => :receiver_currency
    },
    :companies => {:__none__ => :currency},
    :financial_years => {:__none__ => :currency},
    :incoming_deliveries => {:currency_id => :currency},
    :journal_entries => {:currency_id => :currency},
    :journals => {:currency_id => :currency},
    :outgoing_deliveries => {:currency_id => :currency},
    :prices => {:currency_id => :currency},
    :purchases => {:currency_id => :currency},
    :sales => {:currency_id => :currency}
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  COLUMNS = {
    :journal_entries => {
      :currency_debit  => :original_debit,
      :currency_credit => :original_credit,
      :currency_rate   => :original_currency_rate,
      :currency        => :original_currency
    },
    :journal_entry_lines => {
      :currency_debit  => :original_debit,
      :currency_credit => :original_credit
    }    
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  TABLES = ["account_balances", "accounts", "areas", "asset_depreciations", "assets", "bank_statements", "cash_transfers", "cashes", "companies", "contacts", "cultivations", "currencies", "custom_field_choices", "custom_field_data", "custom_fields", "delays", "departments", "deposit_lines", "deposits", "districts", "document_templates", "documents", "entities", "entity_categories", "entity_link_natures", "entity_links", "entity_natures", "establishments", "event_natures", "events", "financial_years", "incoming_deliveries", "incoming_delivery_lines", "incoming_delivery_modes", "incoming_payment_modes", "incoming_payment_uses", "incoming_payments", "inventories", "inventory_lines", "journal_entries", "journal_entry_lines", "journals", "land_parcel_groups", "land_parcel_kinships", "land_parcels", "listing_node_items", "listing_nodes", "listings", "mandates", "observations", "operation_lines", "operation_natures", "operation_uses", "operations", "outgoing_deliveries", "outgoing_delivery_lines", "outgoing_delivery_modes", "outgoing_payment_modes", "outgoing_payment_uses", "outgoing_payments", "preferences", "prices", "product_categories", "product_components", "production_chain_conveyors", "production_chain_work_center_uses", "production_chain_work_centers", "production_chains", "products", "professions", "purchase_lines", "purchases", "roles", "sale_lines", "sale_natures", "sales", "sequences", "stock_moves", "stock_transfers", "stocks", "subscription_natures", "subscriptions", "tax_declarations", "taxes", "tools", "tracking_states", "trackings", "transfers", "transports", "units", "users", "warehouses"]

  def up
    remove_column :bank_statements, :currency_debit
    remove_column :bank_statements, :currency_credit

    currencies = {}
    for result in connection.select_all("SELECT id, code FROM #{quoted_table_name(:currencies)} WHERE code != 'EUR'")
      code = result['code'].upcase[0..2]
      currencies[code] ||= []
      currencies[code] << result['id']
    end
    cases = if currencies.size > 0 
              (lambda do |id_column|
                 "CASE " + currencies.collect do |code, ids|
                   "WHEN #{id_column} IN (#{ids.join(', ')}) THEN '#{code}'"
                 end.join(" ") + " ELSE 'EUR' END"
               end)
            else
              lambda{|id_column| "'EUR'"}
            end
    for table, changes in CURRENCIES
      for id_column, code_column in changes
        add_column table, code_column, :string, :limit => 3
        add_index table, code_column
        if id_column == :__none__
          execute "UPDATE #{quoted_table_name(table)} SET #{code_column} = 'EUR'"
        else
          execute "UPDATE #{quoted_table_name(table)} SET #{code_column} = " + cases[id_column]
          remove_column(table, id_column)
        end
      end
    end

    for table, renamings in COLUMNS
      for old_column, new_column in renamings
        rename_column table, old_column, new_column
        execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new_column}', name = REPLACE(name, '#{old_column}', '#{new_column}') WHERE name LIKE '#{old_column}' AND attribute_name LIKE '#{table.to_s.singularize}%.#{old_column}'"
      end
    end

    for table in TABLES
      for column in columns(table)
        if column.type == :decimal
          change_column(table, column.name, :decimal, :precision => 19, :scale => ((column.scale >= 6 or column.name.match(/(coefficient|rate)/)) ? 10 : 4), :null=>column.null, :default=>column.default)
        end
      end
    end

    drop_table :currencies
  end

  def down
    create_table "currencies", :force => true do |t|
      t.string "name", :null => false
      t.string "code", :null => false
      t.string "value_format", :limit => 16, :null => false
      t.decimal "rate", :precision => 16, :scale => 6, :default => 1.0, :null => false
      t.boolean "active", :default => true, :null => false
      t.text "comment"
      t.integer "company_id", :null => false
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
      t.integer "creator_id"
      t.integer "updater_id"
      t.integer "lock_version", :default => 0, :null => false
      t.boolean "by_default", :default => false, :null => false
      t.string "symbol", :default => "-", :null => false
    end

    add_index "currencies", ["active"], :name => "index_currencies_on_active"
    add_index "currencies", ["code", "company_id"], :name => "index_currencies_on_code_and_company_id", :unique => true
    add_index "currencies", ["company_id"], :name => "index_currencies_on_company_id"
    add_index "currencies", ["created_at"], :name => "index_currencies_on_created_at"
    add_index "currencies", ["creator_id"], :name => "index_currencies_on_creator_id"
    add_index "currencies", ["name"], :name => "index_currencies_on_name"
    add_index "currencies", ["updated_at"], :name => "index_currencies_on_updated_at"
    add_index "currencies", ["updater_id"], :name => "index_currencies_on_updater_id"


    # No back procedure for decimals !

    # Renamings
    for table, renamings in COLUMNS.reverse
      for new_column, old_column in renamings
        execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new_column}', name = REPLACE(name, '#{old_column}', '#{new_column}') WHERE name LIKE '#{old_column}' AND attribute_name LIKE '#{table.to_s.singularize}%.#{old_column}'"
        rename_column table, old_column, new_column
      end
    end

    # Currency ids
    companies = {}
    for table, changes in CURRENCIES.reverse
      for id_column, code_column in changes
        for result in connection.select_all("SELECT DISTINCT company_id, #{code_column} AS codes FROM #{quoted_table_name(table)}")
          cid, code = result['company_id'].to_i, result['code']||'EUR'
          companies[cid] ||= []
          companies[cid] << code unless companies[cid].include?(code)
        end
      end
    end
    puts companies.inspect
    for company, codes in companies
      for code in codes
        execute "INSERT INTO #{quoted_table_name(:currencies)}(name, code, value_format, company_id, created_at, updated_at, by_default) SELECT '#{code}', '#{code}', '%n%u', #{company}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, #{code == 'EUR' ? quoted_true : quoted_false}"
      end
    end
    currencies = {}
    for result in connection.select_all("SELECT id, code, company_id FROM #{quoted_table_name(:currencies)}")
      currencies[result['code']+result['company_id']] = result['id']
    end
    cases =lambda do |code_column|
      "CASE " + currencies.collect do |key, id|
        "WHEN #{code_column}||company_id = '#{key}' THEN #{id}"
      end.join(" ") + " END"
    end
    for table, changes in CURRENCIES.reverse
      for id_column, code_column in changes
        if id_column != :__none__
          add_column table, id_column, :string, :limit => 3
          add_index table, id_column
          execute "UPDATE #{quoted_table_name(table)} SET #{id_column} = " + cases[code_column]
        end
        remove_column(table, code_column)
      end
    end

    add_column :bank_statements, :currency_credit, :decimal, :precision => 16, :scale =>2, :null=>false, :default => 0.0
    add_column :bank_statements, :currency_debit, :decimal, :precision => 16, :scale =>2, :null=>false, :default => 0.0
  end
end
