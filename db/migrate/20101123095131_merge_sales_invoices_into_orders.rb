class MergeSalesInvoicesIntoOrders < ActiveRecord::Migration

  TRACKINGS = {:sales_orders=>[:rebuilt_id, :sales_invoice_id], :sales_order_lines=>[:rebuilt_id, :sales_invoice_line_id]}.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  ORIGINS = {:sales_orders=>:sales_invoice_id, :sales_order_lines=>:sales_invoice_line_id}.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  ORDER_LINES = {:outgoing_delivery_lines=>:order_line_id, :sales_order_lines=>:reduction_origin_id, :subscriptions=>:sales_order_line_id}.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  MERGES = [:subscriptions, :outgoing_deliveries]
  POLYMORPHICS= {:documents=>:owner, :incoming_payment_uses=>:expense, :journal_entries=>:resource, :operations=>:target, :preferences=>:record_value, :stock_moves=>:origin}.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s} # :stocks=>:origin, 
  TEMPLATES = {
    'sales_invoice/created_on' => 'sales_invoice/invoiced_on',
    'sales_invoice.sales_order' => 'sales_invoice'
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  RENAMED_TABLES = {
    :sales_orders=>:sales, 
    :sales_order_lines=>:sale_lines,
    :sales_order_natures=>:sale_natures,
    :purchase_orders=>:purchases,
    :purchase_order_lines=>:purchase_lines
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  STOCKABLE_TABLES = [:incoming_delivery_lines, :inventory_lines, :operation_lines, :outgoing_delivery_lines, :stock_transfers]

  # Minimum columns
  SI = [:accounted_at, :amount, :annotation, :client_id, :company_id, :contact_id, :created_at, :creator_id, :credit, :currency_id, :downpayment_amount, :has_downpayment, :journal_entry_id, :lock_version, :lost, :number, :origin_id, :payment_delay_id, :payment_on, :pretax_amount, :sales_order_id, :updated_at, :updater_id]
  
  #
  SIL = [:amount, :annotation, :company_id, :created_at, :creator_id, :entity_id, :lock_version, :order_line_id, :origin_id, :position, :pretax_amount, :price_id, :product_id, :quantity, :sales_invoice_id, :tracking_id, :updated_at, :updater_id, :warehouse_id] # , :unit_id

  SO = [:accounted_at, :amount, :annotation, :origin_id, :client_id, :comment, :company_id, :conclusion, :confirmed_on, :contact_id, :created_at, :created_on, :creator_id, :currency_id, :delivery_contact_id, :downpayment_amount, :expiration_id, :expired_on, :function_title, :has_downpayment, :initial_number, :introduction, :invoice_contact_id, :invoiced_on, :journal_entry_id, :letter_format, :lock_version, :lost, :nature_id, :number, :paid_amount, :payment_delay_id, :payment_on, :pretax_amount, :reference_number, :responsible_id, :sales_invoice_id, :state, :subject, :sum_method, :transporter_id, :updated_at, :updater_id]

  SOL = [:account_id, :amount, :annotation, :origin_id, :company_id, :created_at, :creator_id, :entity_id, :invoiced, :label, :lock_version, :order_id, :position, :pretax_amount, :price_amount, :price_id, :product_id, :quantity, :reduction_origin_id, :reduction_percent, :sales_invoice_line_id, :tax_id, :tracking_id, :unit_id, :updated_at, :updater_id, :warehouse_id]

  STATES_TABLE = [:sales_orders, :purchase_orders]
  STATES = {
    :ready=>:estimate,
    :processing=>:order,
    :invoiced=>:invoice,
  }
  

  PREFERENCES = {
    :purchase_orders_sequence => :purchases_sequence,
    :sales_orders_sequence => :sales_sequence
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  RIGHTS = {
    :change_prices_on_sales_order => :chnage_prices_on_sales,
    :consult_purchase_orders => :consult_purchases,
    :consult_sale_orders => :consult_sales,
    :give_discounts_on_sales_orders => :give_discounts_on_sales,
    :manage_purchase_orders => :manage_purchases,
    :manage_sales_order_natures => :manage_sale_natures,
    :manage_sales_orders => :manage_sales
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}

  def self.up
    # Change states
    for table in STATES_TABLE
      execute "UPDATE #{quoted_table_name(table)} SET state=CASE "+STATES.collect{|o, n| "WHEN state='#{o}' THEN '#{n}'"}.join(" ")+" WHEN state='finished' THEN 'invoice' ELSE state END"
    end

    rename_column :purchase_orders, :moved_on, :invoiced_on

    add_column :sales_orders, :invoiced_on, :date
    add_column :sales_orders, :credit, :boolean, :null=>false, :default=>false
    add_column :sales_orders, :lost, :boolean, :null=>false, :default=>false
    add_column :sales_orders, :payment_on, :date
    add_column :sales_orders, :origin_id, :integer
    add_column :sales_orders, :sales_order_id, :integer
    add_column :sales_orders, :initial_number, :string, :limit=>64
    change_column_null :sales_orders, :nature_id, true 
    change_column_null :sales_orders, :expiration_id, true
    change_column_null :sales_orders, :expired_on, true
    
    add_column :sales_order_lines, :order_line_id, :integer
    add_column :sales_order_lines, :origin_id, :integer
    add_column :sales_order_lines, :sales_invoice_id, :integer
    change_column_null :sales_order_lines, :unit_id, true
    change_column_null :sales_order_lines, :account_id, true
    remove_column :sales_order_lines, :invoiced

    add_column :products, :deliverable, :boolean, :null=>false, :default=>false
    rename_column :products, :manage_stocks, :stockable
    add_column :products, :trackable, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quoted_table_name(:products)} SET deliverable = stockable WHERE stockable = #{quoted_true}"
    remove_column :stock_moves, :second_move_id
    remove_column :stock_moves, :second_warehouse_id
    change_column_null :stock_moves, :generated, false, false
    execute "UPDATE #{quoted_table_name(:stock_moves)} SET virtual = #{quoted_false} WHERE virtual IS NULL"
    change_column_null :stock_moves, :virtual, false, false
    remove_column :stocks, :origin_id
    remove_column :stocks, :origin_type
    for table in STOCKABLE_TABLES
      add_column table, :stock_move_id, :integer
    end
    add_column :stock_transfers, :second_stock_move_id, :integer
    add_column :stock_transfers, :number, :string, :limit=>64
    execute "UPDATE #{quoted_table_name(:stock_transfers)} SET number = id"
    change_column_null :stock_transfers, :number, false
    # Merge existing virtual and real moves
    on = [:product_id, :origin_type, :origin_id, :unit_id, :warehouse_id, :quantity]

    create_table(:deletable_stock_moves, :force=>true, :id=>false, :stamp=>false) { |t| t.column(:id, :integer) }
    execute "INSERT INTO #{quoted_table_name(:deletable_stock_moves)}(id) SELECT virt_moves.id FROM #{quoted_table_name(:stock_moves)} AS virt_moves JOIN #{quoted_table_name(:stock_moves)} AS real_moves ON (virt_moves.virtual = #{quoted_true} AND real_moves.virtual=#{quoted_false} AND "+on.collect{|x| "virt_moves.#{x}=real_moves.#{x}"}.join(' AND ')+" AND ((virt_moves.tracking_id IS NULL AND real_moves.tracking_id IS NULL) OR virt_moves.tracking_id=real_moves.tracking_id) )"
    execute "DELETE FROM #{quoted_table_name(:stock_moves)} WHERE id IN (SELECT id FROM #{quoted_table_name(:deletable_stock_moves)})"
    drop_table :deletable_stock_moves

    # execute "DELETE FROM #{quoted_table_name(:stock_moves)} WHERE id IN (SELECT virt_moves.id FROM #{quoted_table_name(:stock_moves)} AS virt_moves JOIN #{quoted_table_name(:stock_moves)} AS real_moves ON (virt_moves.virtual = #{quoted_true} AND real_moves.virtual=#{quoted_false} AND "+on.collect{|x| "virt_moves.#{x}=real_moves.#{x}"}.join(' AND ')+" AND ((virt_moves.tracking_id IS NULL AND real_moves.tracking_id IS NULL) OR virt_moves.tracking_id=real_moves.tracking_id) ))"

    add_column :inventories, :moved_on, :date


    for table, columns in TRACKINGS
      for column in columns
        add_column table, column, :integer
        add_index table, column
      end
    end
    
    # puts connection.columns(:sales_orders).collect{|c| c.name}.sort.collect{|c| c.to_sym}.inspect
    # puts connection.columns(:sales_order_lines).collect{|c| c.name}.sort.collect{|c| c.to_sym}.inspect

    defaults = {}
    connection.columns(:sales_order_lines).select{|c| !c.default.nil?}.each{|c| defaults[c.name.to_sym] = c.default}

    # Rebuild invoiced sales orders
    # puts connection.select_one("SELECT count(*) FROM #{quoted_table_name(:sales_orders)}").inspect
    so = connection.columns(:sales_orders).collect{|c| c.name}.sort.collect{|c| c.to_sym}.delete_if{|c| [:id, :sales_invoice_id, :initial_number, :invoiced_on, :rebuilt_id].include? c}
    sol = connection.columns(:sales_order_lines).collect{|c| c.name}.sort.collect{|c| c.to_sym}.delete_if{|c| [:id, :sales_invoice_line_id, :order_id, :rebuilt_id].include? c}
    si = connection.columns(:sales_invoices).collect{|c| c.name}.sort.collect{|c| c.to_sym}
    sil = connection.columns(:sales_invoice_lines).collect{|c| c.name}.sort.collect{|c| c.to_sym}
    execute "INSERT INTO #{quoted_table_name(:sales_orders)} (sales_invoice_id, initial_number, invoiced_on, rebuilt_id, "+so.join(', ')+") SELECT si.id, so.number, si.created_on, so.id, "+so.collect{|c| (si.include?(c) ? "COALESCE(si.#{c}, so.#{c})" : "so.#{c}")}.join(', ')+" FROM #{quoted_table_name(:sales_invoices)} AS si JOIN #{quoted_table_name(:sales_orders)} AS so ON (si.sales_order_id=so.id)"
    execute "INSERT INTO #{quoted_table_name(:sales_order_lines)} (sales_invoice_line_id, order_id, rebuilt_id, "+sol.join(', ')+") SELECT sil.id, so.id, sol.id, "+sol.collect{|c| "COALESCE("+(sil.include?(c) ? "sil.#{c}, " : "")+"sol.#{c}#{', '+connection.quote(defaults[c]) unless defaults[c].nil?})"}.join(', ')+" FROM #{quoted_table_name(:sales_invoice_lines)} AS sil JOIN #{quoted_table_name(:sales_orders)} AS so ON (so.sales_invoice_id=sil.sales_invoice_id) LEFT JOIN #{quoted_table_name(:sales_order_lines)} AS sol ON (sil.order_line_id=sol.id)"
    #
    create_table(:deletable_sales_order_lines, :force=>true, :id=>false, :stamp=>false) { |t| t.column(:id, :integer) }
    execute "INSERT INTO #{quoted_table_name(:deletable_sales_order_lines)}(id) SELECT rebuilt_id FROM #{quoted_table_name(:sales_order_lines)} WHERE rebuilt_id IS NOT NULL"
    create_table(:deletable_sales_orders, :force=>true, :id=>false, :stamp=>false) { |t| t.column(:id, :integer) }
    execute "INSERT INTO #{quoted_table_name(:deletable_sales_orders)}(id) SELECT rebuilt_id FROM #{quoted_table_name(:sales_orders)} WHERE rebuilt_id IS NOT NULL"
    #
    execute "DELETE FROM #{quoted_table_name(:sales_order_lines)} WHERE id IN (SELECT id FROM #{quoted_table_name(:deletable_sales_order_lines)})"
    execute "DELETE FROM #{quoted_table_name(:sales_orders)} WHERE id IN (SELECT id FROM #{quoted_table_name(:deletable_sales_orders)})"
    execute "DELETE FROM #{quoted_table_name(:sales_invoice_lines)} WHERE sales_invoice_id IN (SELECT sales_invoice_id FROM #{quoted_table_name(:sales_orders)})"
    execute "DELETE FROM #{quoted_table_name(:sales_invoices)} WHERE id IN (SELECT sales_invoice_id FROM #{quoted_table_name(:sales_orders)})"
    # puts connection.select_one("SELECT count(*) FROM #{quoted_table_name(:sales_orders)}").inspect
    drop_table :deletable_sales_orders
    drop_table :deletable_sales_order_lines



    # Add uninvoiced sales orders
    execute "INSERT INTO #{quoted_table_name(:sales_orders)} (sales_invoice_id, created_on, confirmed_on, invoiced_on, delivery_contact_id, invoice_contact_id, paid_amount, responsible_id, state, "+SI.join(', ')+") SELECT id, created_on, created_on, created_on, contact_id, contact_id, CASE WHEN paid THEN amount ELSE 0.0 END, creator_id, 'invoice', "+SI.join(', ')+" FROM #{quoted_table_name(:sales_invoices)}"
    execute "INSERT INTO #{quoted_table_name(:sales_order_lines)} (sales_invoice_line_id, order_id, label, unit_id, "+SIL.join(', ')+") SELECT sil.id, so.id, p.catalog_name, COALESCE(sil.unit_id, p.unit_id), "+SIL.collect{|x| "sil.#{x}"}.join(', ')+" FROM #{quoted_table_name(:sales_invoice_lines)} AS sil JOIN #{quoted_table_name(:sales_orders)} AS so ON (so.sales_invoice_id=sil.sales_invoice_id) LEFT JOIN #{quoted_table_name(:products)} AS p ON (sil.product_id=p.id)"
    # puts connection.select_one("SELECT count(*) FROM #{quoted_table_name(:sales_orders)}").inspect

    # Origins in
    for table, column in ORIGINS
      origin = :origin_id
      say_with_time("reindex_#{table}_#{origin}") do
        suppress_messages do
          for rec in connection.select_all("SELECT DISTINCT rec.#{origin} AS osoid, so.id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(table)} AS so ON (rec.#{origin}=so.#{column})")
            execute "UPDATE #{quoted_table_name(table)} SET #{origin} = #{rec['soid']} WHERE #{origin} = #{rec['osoid']}"
          end    
        end
      end
    end

    # Order Lines
    for table, column in ORDER_LINES
      say_with_time("reindex_#{table}_#{column}") do
        suppress_messages do
          for rec in connection.select_all("SELECT DISTINCT rec.#{column} AS osolid, sol.id AS solid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_order_lines)} AS sol ON (rec.#{column}=sol.rebuilt_id)")
            execute "UPDATE #{quoted_table_name(table)} SET #{column} = #{rec['solid']} WHERE #{column} = #{rec['osolid']}"
          end
        end    
      end
    end

    # Merge sales_order_id and sales_invoice_id
    for table in MERGES
      add_index table, :sales_invoice_id
      add_index table, :sales_order_id
      if connection.adapter_name == "PostgreSQL"
        execute "UPDATE #{quoted_table_name(table)} SET sales_order_id = so.id FROM #{quoted_table_name(:sales_orders)} AS so WHERE #{quoted_table_name(table)}.sales_invoice_id=so.sales_invoice_id OR #{quoted_table_name(table)}.sales_order_id=so.rebuilt_id"
      else
        say_with_time("merge_#{table}_sales_order_id_with_sales_invoice_id") do
          suppress_messages do
            for rec in connection.select_all("SELECT DISTINCT rec.sales_order_id AS osoid, rec.sales_invoice_id AS osiid, so.id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_orders)} AS so ON (rec.sales_invoice_id=so.sales_invoice_id OR rec.sales_order_id=so.rebuilt_id)")
              execute "UPDATE #{quoted_table_name(table)} SET sales_order_id = #{rec['soid']} WHERE sales_invoice_id = #{rec['osiid']||-1} OR sales_order_id = #{rec['osoid']||-1}"
            end
          end
        end
      end
      remove_index table, :sales_invoice_id
      remove_column table, :sales_invoice_id
    end

    # Polymorphic keys
    for table, column in POLYMORPHICS
      say_with_time("reindex_#{table}_#{column}_id") do
        suppress_messages do
          for rec in connection.select_all("SELECT DISTINCT rec.#{column}_id AS osoid, so.id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_orders)} AS so ON (rec.#{column}_id=so.rebuilt_id) WHERE #{column}_type LIKE 'Sale%Order'")
            execute "UPDATE #{quoted_table_name(table)} SET #{column}_id = #{rec['soid']}, #{column}_type='SalesOrder' WHERE #{column}_id = #{rec['osoid']} and #{column}_type LIKE 'Sale%Order'"
          end
          for rec in connection.select_all("SELECT DISTINCT rec.#{column}_id AS osoid, sol.id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_order_lines)} AS sol ON (rec.#{column}_id=sol.rebuilt_id) WHERE #{column}_type LIKE 'Sale%OrderLine'")
            execute "UPDATE #{quoted_table_name(table)} SET #{column}_id = #{rec['soid']}, #{column}_type='SalesOrderLine' WHERE #{column}_id = #{rec['osoid']} and #{column}_type LIKE 'Sale%OrderLine'"
          end
          for rec in connection.select_all("SELECT DISTINCT rec.#{column}_id AS osoid, so.id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_orders)} AS so ON (rec.#{column}_id=so.sales_invoice_id) WHERE #{column}_type LIKE '%Invoice'")
            execute "UPDATE #{quoted_table_name(table)} SET #{column}_id = #{rec['soid']}, #{column}_type='SalesOrder' WHERE #{column}_id = #{rec['osoid']} and #{column}_type LIKE '%Invoice'"
          end
          for rec in connection.select_all("SELECT DISTINCT rec.#{column}_id AS osoid, sol.id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_order_lines)} AS sol ON (rec.#{column}_id=sol.sales_invoice_line_id) WHERE #{column}_type LIKE '%InvoiceLine'")
            execute "UPDATE #{quoted_table_name(table)} SET #{column}_id = #{rec['soid']}, #{column}_type='SalesOrderLine' WHERE #{column}_id = #{rec['osoid']} and #{column}_type LIKE 'Sale%OrderLine'"
          end
        end
      end      
    end

    for table, columns in TRACKINGS
      for column in columns
        remove_index table, column
        remove_column table, column
      end
    end

    remove_column :sales_orders, :sales_order_id
    remove_column :sales_order_lines, :order_line_id
    remove_column :sales_order_lines, :sales_invoice_id

    execute "UPDATE #{quoted_table_name(:sales_orders)} SET paid_amount = 0.0 WHERE paid_amount IS NULL"
    change_column_null :sales_orders, :paid_amount, false, 0.0

    drop_table :sales_invoices
    drop_table :sales_invoice_lines

    for o, n in RENAMED_TABLES
      rename_table o, n
      for table, column in POLYMORPHICS
        execute "UPDATE #{quoted_table_name(table)} SET #{column}_type='#{n.to_s.classify}' WHERE #{column}_type = '#{o.to_s.classify}'"
      end
    end
    rename_column :incoming_deliveries, :purchase_order_id, :purchase_id
    rename_column :incoming_delivery_lines, :order_line_id, :purchase_line_id
    rename_column :outgoing_deliveries, :sales_order_id, :sale_id
    rename_column :outgoing_delivery_lines, :order_line_id, :sale_line_id
    rename_column :purchase_lines, :order_id, :purchase_id
    rename_column :sale_lines, :order_id, :sale_id
    rename_column :subscriptions, :sales_order_id, :sale_id
    rename_column :subscriptions, :sales_order_line_id, :sale_line_id
    rename_column :transports, :purchase_order_id, :purchase_id

    for o, n in TEMPLATES
      execute "UPDATE #{quoted_table_name(:document_templates)} SET source=REPLACE(source, '#{o}', '#{n}'), cache=''"
    end

    for o, n in PREFERENCES
      execute "UPDATE #{quoted_table_name(:preferences)} SET name='#{n}' WHERE name='#{o}'"
    end

    for o, n in RIGHTS
      execute "UPDATE #{quoted_table_name(:users)} SET rights=REPLACE(rights, '#{o}', '#{n}')"
      execute "UPDATE #{quoted_table_name(:roles)} SET rights=REPLACE(rights, '#{o}', '#{n}')"
    end

    for o, n in RENAMED_TABLES
      execute "UPDATE #{quoted_table_name(:event_natures)} SET usage='#{n.to_s.singularize}' WHERE usage='#{o.to_s.singularize}'"
    end
    
  end

  def self.down
    for n, o in RENAMED_TABLES.reverse
      execute "UPDATE #{quoted_table_name(:event_natures)} SET usage='#{n.to_s.singularize}' WHERE usage='#{o.to_s.singularize}'"
    end

    for n, o in RIGHTS.reverse
      execute "UPDATE #{quoted_table_name(:roles)} SET rights=REPLACE(rights, '#{o}', '#{n}')"
      execute "UPDATE #{quoted_table_name(:users)} SET rights=REPLACE(rights, '#{o}', '#{n}')"
    end

    for n, o in PREFERENCES.reverse
      execute "UPDATE #{quoted_table_name(:preferences)} SET name='#{n}' WHERE name='#{o}'"
    end

    for n, o in TEMPLATES.reverse
      execute "UPDATE #{quoted_table_name(:document_templates)} SET source=REPLACE(source, '#{o}', '#{n}'), cache=''"
    end

    rename_column :transports, :purchase_id, :purchase_order_id
    rename_column :subscriptions, :sale_line_id, :sales_order_line_id
    rename_column :subscriptions, :sale_id, :sales_order_id
    rename_column :sale_lines, :sale_id, :order_id
    rename_column :purchase_lines, :purchase_id, :order_id
    rename_column :outgoing_delivery_lines, :sale_line_id, :order_line_id
    rename_column :outgoing_deliveries, :sale_id, :sales_order_id
    rename_column :incoming_delivery_lines, :purchase_line_id, :order_line_id
    rename_column :incoming_deliveries, :purchase_id, :purchase_order_id

    for n, o in RENAMED_TABLES.reverse
      for table, column in POLYMORPHICS.reverse
        execute "UPDATE #{quoted_table_name(table)} SET #{column}_type='#{n.to_s.classify}' WHERE #{column}_type = '#{o.to_s.classify}'"
      end
      rename_table o, n
    end
    
    create_table :sales_invoice_lines do |t|
      t.integer  "order_line_id"
      t.integer  "product_id",                                                       :null => false
      t.integer  "price_id",                                                         :null => false
      t.decimal  "quantity",         :precision => 16, :scale => 4, :default => 1.0, :null => false
      t.decimal  "pretax_amount",    :precision => 16, :scale => 2, :default => 0.0, :null => false
      t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
      t.integer  "position"
      t.integer  "company_id",                                                       :null => false
      t.integer  "sales_invoice_id"
      t.integer  "origin_id"
      t.text     "annotation"
      t.integer  "entity_id"
      t.integer  "unit_id"
      t.integer  "tracking_id"
      t.integer  "warehouse_id"
    end

    add_index :sales_invoice_lines, ["company_id"], :name => "index_invoice_lines_on_company_id"

    create_table :sales_invoices do |t|
      t.integer  "client_id",                                                                          :null => false
      t.string   "nature",             :limit => 1,                                                    :null => false
      t.string   "number",             :limit => 64,                                                   :null => false
      t.decimal  "pretax_amount",                    :precision => 16, :scale => 2, :default => 0.0,   :null => false
      t.decimal  "amount",                           :precision => 16, :scale => 2, :default => 0.0,   :null => false
      t.integer  "payment_delay_id",                                                                   :null => false
      t.date     "payment_on",                                                                         :null => false
      t.boolean  "paid",                                                            :default => false, :null => false
      t.boolean  "lost",                                                            :default => false, :null => false
      t.boolean  "has_downpayment",                                                 :default => false, :null => false
      t.decimal  "downpayment_amount",               :precision => 16, :scale => 2, :default => 0.0,   :null => false
      t.integer  "contact_id"
      t.integer  "company_id",                                                                         :null => false
      t.integer  "sales_order_id"
      t.integer  "origin_id"
      t.boolean  "credit",                                                          :default => false, :null => false
      t.date     "created_on"
      t.text     "annotation"
      t.integer  "currency_id"
      t.datetime "accounted_at"
      t.integer  "journal_entry_id"
    end

    add_index :sales_invoices, ["accounted_at"], :name => "index_invoices_on_accounted_at"
    add_index :sales_invoices, ["company_id"], :name => "index_invoices_on_company_id"

    change_column_null :sales_orders, :paid_amount, true


    si = SI - [:sales_order_id, :nature, :payment_on]
    sil = SIL + [:unit_id] - [:sales_invoice_id, :order_line_id]
    execute "INSERT INTO #{quoted_table_name(:sales_invoices)} (sales_order_id, nature, payment_on, created_on, "+si.join(', ')+") SELECT id, CASE WHEN credit = #{quoted_true} THEN 'C' ELSE 'S' END, COALESCE(invoiced_on, created_on), COALESCE(invoiced_on, created_on), "+si.join(', ')+" FROM #{quoted_table_name(:sales_orders)} WHERE state = 'invoice'"
    execute "INSERT INTO #{quoted_table_name(:sales_invoice_lines)} (sales_invoice_id, order_line_id, "+sil.join(', ')+") SELECT si.id, sol.id, "+sil.collect{|c| "sol.#{c}"}.join(', ')+" FROM #{quoted_table_name(:sales_order_lines)} AS sol JOIN #{quoted_table_name(:sales_invoices)} AS si ON (si.sales_order_id=sol.order_id)"    

    # Don't touch polymorphic keys because not sure to be well come
    
    # Spread sales_order_id in sales_invoice_id
    for table in MERGES.reverse
      add_column table, :sales_invoice_id, :integer
      add_index table, :sales_invoice_id
      if connection.adapter_name == "PostgreSQL"
        execute "UPDATE #{quoted_table_name(table)} SET sales_invoice_id = si.id FROM #{quoted_table_name(:sales_invoices)} AS si WHERE #{quoted_table_name(table)}.sales_order_id=si.sales_order_id"
      else
        say_with_time("spread_#{table}_sales_order_id_in_sales_invoice_id") do
          suppress_messages do
            for rec in connection.select_all("SELECT DISTINCT si.id AS siid, si.sales_order_id AS soid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(:sales_invoices)} AS si ON (rec.sales_order_id=si.sales_order_id)")
              execute "UPDATE #{quoted_table_name(table)} SET sales_invoice_id = #{rec['siid']} WHERE sales_order_id = #{rec['soid']}"
            end
          end
        end
      end
      remove_index table, :sales_order_id
      remove_index table, :sales_invoice_id
    end

    # Order Lines: Nothing to do
    
    # Origins in
    for table, column in {:sales_invoices=>:sales_order_id, :sales_invoice_lines=>:order_line_id}
      origin = :origin_id
      say_with_time("reindex_#{table}_#{origin}") do
        suppress_messages do
          for rec in connection.select_all("SELECT DISTINCT rec.#{origin} AS osiid, si.id AS siid FROM #{quoted_table_name(table)} AS rec JOIN #{quoted_table_name(table)} AS si ON (rec.#{origin}=si.#{column})")
            execute "UPDATE #{quoted_table_name(table)} SET #{origin} = #{rec['siid']} WHERE #{origin} = #{rec['osiid']}"
          end    
        end
      end
    end

    remove_column :inventories, :moved_on

    cols = columns(:stock_moves).collect{|c| c.name}.delete_if{|c| ["id", "virtual"].include?(c.to_s)}.join(', ')
    execute "INSERT INTO #{quoted_table_name(:stock_moves)} (#{cols}, virtual) SELECT #{cols}, #{quoted_true} FROM #{quoted_table_name(:stock_moves)} WHERE virtual=#{quoted_false}"
    remove_column :stock_transfers, :number
    remove_column :stock_transfers, :second_stock_move_id
    for table in STOCKABLE_TABLES.reverse
      remove_column table, :stock_move_id
    end
    add_column :stocks, :origin_type, :string
    add_column :stocks, :origin_id, :integer
    # change_column_null :stock_moves, :virtual, false, false
    # change_column_null :stock_moves, :generated, false, false
    add_column :stock_moves, :second_warehouse_id, :integer
    add_column :stock_moves, :second_move_id, :integer
    remove_column :products, :trackable
    rename_column :products, :stockable, :manage_stocks
    remove_column :products, :deliverable

    add_column :sales_order_lines, :invoiced, :boolean, :null=>false, :default=>false
    # change_column_null :sales_order_lines, :account_id, true
    # change_column_null :sales_order_lines, :unit_id, true
    # remove_column :sales_order_lines, :sales_invoice_id # NOT USED for rollback
    remove_column :sales_order_lines, :origin_id
    # remove_column :sales_order_lines, :order_line_id # NOT USED for rollback
    # change_column_null :sales_orders, :expired_on, true
    # change_column_null :sales_orders, :expiration_id, true
    # change_column_null :sales_orders, :nature_id, true 
    execute "UPDATE #{quoted_table_name(:sales_orders)} SET number=COALESCE(initial_number, '**'||number||'**', '??????') WHERE state = 'invoice'"
    remove_column :sales_orders, :initial_number
    # remove_column :sales_orders, :sales_order_id # NOT USED for rollback
    remove_column :sales_orders, :origin_id
    remove_column :sales_orders, :payment_on
    remove_column :sales_orders, :lost
    remove_column :sales_orders, :credit
    remove_column :sales_orders, :invoiced_on

    rename_column :purchase_orders, :invoiced_on, :moved_on

    # Change states
    for table in STATES_TABLE.reverse
      execute "UPDATE #{quoted_table_name(table)} SET state=CASE WHEN state='invoice' AND amount=paid_amount THEN 'finished' "+STATES.collect{|n, o| "WHEN state='#{o}' THEN '#{n}'"}.join(" ")+" ELSE state END"
    end

  end
end
