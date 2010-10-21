class CreateProductionChains < ActiveRecord::Migration
  RIGHTS_UPDATES = {
    "manage_sale_payments"       => "manage_incoming_payments",
    "manage_payment_modes"       => "manage_incoming_payment_modes manage_outgoing_payment_modes",
    "manage_sale_delivery_modes" => "manage_outgoing_delivery_modes",
    "manage_sale_order_natures"  => "manage_sales_order_natures",
    "manage_sale_orders"         => "manage_sales_orders",
    "consult_purchases"          => "consult_purchase_orders",
    "consult_invoices"           => "consult_sales_invoices",
    "consult_entries"            => "consult_journal_entries",
    "consult_sale_orders"        => "consult_sales_orders",
    "consult_tracking"           => "consult_trackings",
    "manage_purchases"           => "manage_purchase_orders manage_outgoing_payments",
    "give_discounts_on_sale"     => "give_discounts_on_sales_orders",
    "change_prices_on_sale"      => "change_prices_on_sales_orders"
  }.to_a.sort
  TABLES_UPDATES = {
    :sale_payments           => :incoming_payments,
    :sale_payment_modes      => :incoming_payment_modes,
    :sale_payment_parts      => :incoming_payment_uses,
    :purchase_payments       => :outgoing_payments,
    :purchase_payment_modes  => :outgoing_payment_modes,
    :purchase_payment_parts  => :outgoing_payment_uses,
    :sale_deliveries         => :outgoing_deliveries,
    :sale_delivery_lines     => :outgoing_delivery_lines,
    :sale_delivery_modes     => :outgoing_delivery_modes,
    :purchase_deliveries     => :incoming_deliveries,
    :purchase_delivery_lines => :incoming_delivery_lines,
    :purchase_delivery_modes => :incoming_delivery_modes,
    :sale_orders             => :sales_orders,
    :sale_order_lines        => :sales_order_lines,
    :sale_order_natures      => :sales_order_natures,
    :invoices                => :sales_invoices,
    :invoice_lines           => :sales_invoice_lines
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  POLYMORPHIC_COLUMNS = {
    :documents =>             "owner_type",
    :journal_entries =>       "resource_type",
    :operations =>            "target_type",
    :preferences =>           "record_value_type",
    :incoming_payment_uses => "expense_type",
    :stocks =>                "origin_type",
    :stock_moves =>           "origin_type"
  }.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
  PREFERENCES = {
    "management.payments.numeration" => "management.incoming_payments.numeration",
    "management.purchase_payments.numeration" => "management.outgoing_payments.numeration",
    "management.invoices.numeration" => "management.sales_invoices.numeration",
    "management.sale_orders.numeration" => "management.sales_orders.numeration"
  }.to_a.sort

  def self.up
    for old, new in TABLES_UPDATES
      rename_table old, quoted_table_name(new)
    end
    change_column :event_natures, :usage, :string, :limit=>64
    change_column :document_templates, :nature, :string, :limit=>64
    for old, new in TABLES_UPDATES
      for table, column in POLYMORPHIC_COLUMNS
        execute "UPDATE #{quoted_table_name(table)} SET #{column}='#{new.to_s.classify}' WHERE #{column}='#{old.to_s.classify}'"
      end
      # Document Templates
      execute "UPDATE #{quoted_table_name(:document_templates)} SET source=REPLACE(source, '#{old}', '#{new}'), cache=REPLACE(cache, '#{old}', '#{new}')"
      execute "UPDATE #{quoted_table_name(:document_templates)} SET nature='#{new.to_s.singularize}' WHERE nature='#{old.to_s.singularize}'"
      # Event natures
      execute "UPDATE #{quoted_table_name(:event_natures)} SET usage='#{new.to_s.singularize}' WHERE usage='#{old.to_s.singularize}'"
      # Listings
      execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new.to_s.singularize}' WHERE attribute_name = '#{old.to_s.singularize}'"
      execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new}' WHERE attribute_name = '#{old}'"
    end


    rename_column :sales_invoices, :sale_order_id, :sales_order_id
    rename_column :sales_invoice_lines, :invoice_id, :sales_invoice_id
    rename_column :incoming_deliveries, :order_id, :purchase_order_id
    change_column_null :incoming_deliveries, :purchase_order_id, true
    add_column :incoming_deliveries, :mode_id, :integer # No deliveries can be in the table
    rename_column :outgoing_deliveries, :invoice_id, :sales_invoice_id
    rename_column :outgoing_deliveries, :order_id, :sales_order_id
    add_column :outgoing_delivery_modes, :with_transport, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quoted_table_name(:outgoing_delivery_modes)} SET with_transport=#{quoted_true}"
    rename_column :subscriptions, :invoice_id, :sales_invoice_id
    rename_column :subscriptions, :sale_order_id, :sales_order_id
    rename_column :subscriptions, :sale_order_line_id, :sales_order_line_id
    add_column :transports, :purchase_order_id, :integer
    add_column :transports, :amount, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :transports, :amount_with_taxes, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false

    create_table :land_parcel_groups do |t|
      t.column :name,             :string, :null=>false
      t.column :comment,          :text
      t.column :color,            :string, :limit=>6, :null=>false, :default=>"000000"
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end    
    add_index :land_parcel_groups, :company_id
    
    create_table :land_parcel_kinships do |t|
      t.column :parent_land_parcel_id, :integer, :null=>false
      t.column :child_land_parcel_id,  :integer, :null=>false
      t.column :nature,                :string, :limit=>16 # fusion division
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end    
    add_index :land_parcel_kinships, :company_id
    add_index :land_parcel_kinships, [:parent_land_parcel_id, :company_id]
    add_index :land_parcel_kinships, [:child_land_parcel_id, :company_id]

    create_table :cultivations do |t|
      t.column :name,             :string,  :null=>false
      t.column :started_on,       :date,    :null=>false
      t.column :stopped_on,       :date
      t.column :color,            :string,  :null=>false, :limit=>6, :default=>"FFFFFF"
      t.column :comment,          :text
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :cultivations, :company_id

    create_table :tracking_states do |t|
      t.column :tracking_id,      :integer,  :null=>false
      t.column :responsible_id,   :integer,  :null=>false
      t.column :production_chain_conveyor_id, :integer
      t.column :temperature,      :decimal,  :precision=>16, :scale=>2
      t.column :relative_humidity, :decimal,  :precision=>16, :scale=>2
      t.column :atmospheric_pressure, :decimal,  :precision=>16, :scale=>2
      t.column :luminance,        :decimal,  :precision=>16, :scale=>2
      t.column :total_weight,     :decimal,  :precision=>16, :scale=>2
      t.column :net_weight,       :decimal,  :precision=>16, :scale=>2
      t.column :examinated_at,    :datetime, :null=>false
      t.column :comment,          :text
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :tracking_states, :company_id
    add_index :tracking_states, [:tracking_id, :company_id]
    add_index :tracking_states, [:responsible_id, :company_id]

    create_table :production_chains do |t|
      t.column :name,             :string,   :null=>false
      t.column :comment,          :text
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chains, :company_id


    create_table :production_chain_conveyors do |t|
      t.column :production_chain_id, :integer, :null=>false
      t.column :product_id,       :integer,  :null=>false
      t.column :unit_id,          :integer,  :null=>false
      t.column :flow,             :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0
      t.column :check_state,      :boolean,  :null=>false, :default=>false
      t.column :source_id,        :integer
      t.column :source_quantity,  :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0
      t.column :unique_tracking,  :boolean,  :null=>false, :default=>false
      t.column :target_id,        :integer
      t.column :target_quantity,  :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0
      t.column :comment,          :text
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_conveyors, :company_id
    add_index :production_chain_conveyors, [:production_chain_id, :company_id]


#     create_table :production_chain_tokens do |t|
#       t.column :production_chain_id, :integer, :null=>false
#       t.column :number,           :string,   :null=>false
#       t.column :where_id,         :integer,  :null=>false
#       t.column :where_type,       :string,   :null=>false
#       t.column :started_at,       :datetime, :null=>false
#       t.column :stopped_at,       :datetime
#       t.column :comment,          :text
#       t.column :story,            :text
#       t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
#     end
#     add_index :production_chain_tokens, :company_id
#     add_index :production_chain_tokens, [:production_chain_id, :company_id]
#     add_index :production_chain_tokens, [:where_id, :where_type, :company_id]
    
    

    create_table :production_chain_work_centers do |t|
      t.column :production_chain_id, :integer, :null=>false
      t.column :operation_nature_id, :integer, :null=>false
      t.column :name,             :string,   :null=>false
      t.column :nature,           :string,   :null=>false # One in or One out
      t.column :building_id,      :integer,  :null=>false
      t.column :comment,          :text
      t.column :position,         :integer
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_work_centers, :company_id
    add_index :production_chain_work_centers, [:production_chain_id, :company_id]
    add_index :production_chain_work_centers, [:operation_nature_id, :company_id]


#     create_table :production_chain_work_center_lines do |t|
#       t.column :work_center_id,     :integer,  :null=>false
#       t.column :from_work_center_line_id, :integer, :null=>false
#       t.column :direction,        :string,   :null=>false, :default=>"out"
#       t.column :product_id,       :integer
#       t.column :quantity,         :decimal,  :precision=>16, :scale=>4, :default=>0.0
#       t.column :unit_id,          :integer
#       t.column :warehouse_id,     :integer
#       t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
#     end
#     add_index :production_chain_work_center_lines, :company_id
#     add_index :production_chain_work_center_lines, [:work_center_id, :company_id]
#     add_index :production_chain_work_center_lines, [:work_center_line_id, :company_id]

    create_table :production_chain_work_center_uses do |t|
      t.column :work_center_id,     :integer,  :null=>false
      t.column :tool_id,          :integer,  :null=>false
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_work_center_uses, :company_id
    add_index :production_chain_work_center_uses, [:work_center_id, :company_id]


    rename_table :tool_uses, :operation_uses

    add_column :operations, :production_chain_work_center_id, :integer


    add_column :land_parcels, :started_on, :date
    add_column :land_parcels, :stopped_on, :date

    # Fill cultivation column
    # add_column :land_parcels, :cultivation_id, :integer

    # Fill land_parcels.group_id column
    add_column :land_parcels, :group_id, :integer
    execute "INSERT INTO #{quoted_table_name(:land_parcel_groups)} (name, company_id, created_at, updated_at) SELECT 'Default group of land parcels', id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(:companies)}"
    if (groups = connection.select_all("SELECT id, company_id FROM #{quoted_table_name(:land_parcel_groups)}")).size > 0
      execute "UPDATE #{quoted_table_name(:land_parcels)} SET group_id=CASE "+groups.collect{|g| "WHEN company_id=#{g['company_id']} THEN #{g['id']}"}.join(" ")+" END"
    end
    change_column_null :land_parcels, :group_id, false
    execute "UPDATE #{quoted_table_name(:land_parcels)} SET started_on=#{connection.quote(Date.civil(1901,1,1))}"
    change_column_null :land_parcels, :started_on, false
    remove_column :land_parcels, :master
    remove_column :land_parcels, :parent_id
    remove_column :land_parcels, :polygon

    # Add a the list organization for payment modes
    add_column :incoming_payment_modes, :position, :integer
    execute "UPDATE #{quoted_table_name(:incoming_payment_modes)} SET position = id"
    add_column :outgoing_payment_modes, :position, :integer
    execute "UPDATE #{quoted_table_name(:outgoing_payment_modes)} SET position = id"

    # Some accountancy stuff
    remove_column :journals,   :counterpart_id
    remove_column :warehouses, :account_id
    rename_column :taxes, :account_collected_id, :collected_account_id
    rename_column :taxes, :account_paid_id, :paid_account_id
    rename_column :cash_transfers, :amount, :receiver_amount
    rename_column :cash_transfers, :currency_amount, :emitter_amount
    rename_column :cash_transfers, :currency_id, :emitter_currency_id
    rename_column :cash_transfers, :currency_rate, :emitter_currency_rate
    rename_column :cash_transfers, :journal_entry_id, :emitter_journal_entry_id
    add_column :cash_transfers, :receiver_journal_entry_id, :integer
    add_column :cash_transfers, :receiver_currency_id, :integer
    add_column :cash_transfers, :receiver_currency_rate, :decimal, :precision=>16, :scale=>6
    add_column :cash_transfers, :currency_id, :integer
    add_column :cash_transfers, :created_on, :date


    # Some management stuff
    change_column :sales_orders, :state, :string, :limit=>64
    execute "UPDATE #{quoted_table_name(:sales_orders)} SET state=CASE WHEN state='C' THEN 'finished' WHEN invoiced = #{quoted_true} THEN 'invoiced' WHEN state='A' THEN 'processing' ELSE 'draft' END"
    remove_column :sales_orders, :invoiced
    add_column :purchase_orders, :state, :string, :limit=>64
    execute "UPDATE #{quoted_table_name(:purchase_orders)} SET state='draft'"
    execute "UPDATE #{quoted_table_name(:purchase_orders)} SET state='finished' WHERE parts_amount = amount_with_taxes"
    add_column :incoming_payments, :commission_account_id, :integer
    add_column :incoming_payments, :commission_amount, :decimal, :precision=>16, :scale=>2, :null=>false, :default=>0.0
    rename_column :incoming_payment_modes, :commission_amount, :commission_base_amount
    for mode in connection.select_all("SELECT id, commission_account_id AS aid, commission_percent AS p, commission_base_amount AS ba FROM #{quoted_table_name(:incoming_payment_modes)} WHERE with_commission = #{quoted_true}")
      execute "UPDATE #{quoted_table_name(:incoming_payments)} SET commission_account_id=#{mode['aid']}, commission_amount=(amount*#{mode['p']}/100+#{mode['ba']}) WHERE mode_id=#{mode['id']}"
    end
    rename_column :incoming_payments, :parts_amount, :used_amount
    rename_column :outgoing_payments, :parts_amount, :used_amount
    rename_column :sales_orders, :parts_amount, :paid_amount
    rename_column :purchase_orders, :parts_amount, :paid_amount
    rename_column :transfers, :parts_amount, :paid_amount

    add_column :sales_orders, :reference_number, :string
    add_column :purchase_orders, :confirmed_on, :date
    add_column :purchase_orders, :responsible_id, :integer
    remove_column :purchase_orders, :shipped
    rename_column :purchase_orders, :dest_contact_id, :delivery_contact_id

    add_column :incoming_deliveries, :number, :string
    add_column :incoming_deliveries, :reference_number, :string
    execute "UPDATE #{quoted_table_name(:incoming_deliveries)} SET number='00000000'"
    add_column :outgoing_deliveries, :number, :string
    add_column :outgoing_deliveries, :reference_number, :string
    execute "UPDATE #{quoted_table_name(:outgoing_deliveries)} SET number='00000000'"
    


    # UPDATE RIGHTS
    for old, new in RIGHTS_UPDATES
      execute "UPDATE #{quoted_table_name(:users)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
      execute "UPDATE #{quoted_table_name(:roles)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
    end

    for o, n in PREFERENCES
      execute "UPDATE #{quoted_table_name(:preferences)} SET name='#{n}' WHERE name='#{o}'"
    end
  end

  def self.down
    for n, o in PREFERENCES.reverse
      execute "UPDATE #{quoted_table_name(:preferences)} SET name='#{n}' WHERE name='#{o}'"
    end

    # UPDATE RIGHTS
    for old, new in RIGHTS_UPDATES.reverse
      execute "UPDATE #{quoted_table_name(:users)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
      execute "UPDATE #{quoted_table_name(:roles)} SET rights=REPLACE(rights, '#{old}', '#{new}')"
    end

    # Some management stuff
    remove_column :outgoing_deliveries, :reference_number
    remove_column :outgoing_deliveries, :number
    remove_column :incoming_deliveries, :reference_number
    remove_column :incoming_deliveries, :number

    rename_column :purchase_orders, :delivery_contact_id, :dest_contact_id
    add_column :purchase_orders, :shipped, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quoted_table_name(:purchase_orders)} SET shipped=#{quoted_true} WHERE state='finished'"
    remove_column :purchase_orders, :responsible_id
    remove_column :purchase_orders, :confirmed_on
    remove_column :sales_orders, :reference_number

    rename_column :transfers, :paid_amount, :parts_amount
    rename_column :purchase_orders, :paid_amount, :parts_amount
    rename_column :sales_orders, :paid_amount, :parts_amount
    rename_column :outgoing_payments, :used_amount, :parts_amount
    rename_column :incoming_payments, :used_amount, :parts_amount

    rename_column :incoming_payment_modes, :commission_base_amount, :commission_amount
    remove_column :incoming_payments, :commission_amount
    remove_column :incoming_payments, :commission_account_id
    remove_column :purchase_orders, :state
    add_column :sales_orders, :invoiced, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quoted_table_name(:sales_orders)} SET invoiced=(state='invoiced' OR state='finished'), state=CASE WHEN state='finished' THEN 'C' WHEN state='processing' OR invoiced=#{quoted_true} THEN 'A' ELSE 'E' END"
    # change_column :sales_orders, :state, :string, :limit=>64


    # Some accountancy stuff
    remove_column :cash_transfers, :created_on
    remove_column :cash_transfers, :currency_id
    remove_column :cash_transfers, :receiver_currency_rate
    remove_column :cash_transfers, :receiver_currency_id
    remove_column :cash_transfers, :receiver_journal_entry_id
    rename_column :cash_transfers, :emitter_journal_entry_id, :journal_entry_id
    rename_column :cash_transfers, :emitter_currency_rate, :currency_rate
    rename_column :cash_transfers, :emitter_currency_id, :currency_id
    rename_column :cash_transfers, :emitter_amount, :currency_amount
    rename_column :cash_transfers, :receiver_amount, :amount
    rename_column :taxes, :paid_account_id, :account_paid_id
    rename_column :taxes, :collected_account_id, :account_collected_id
    add_column :warehouses, :account_id, :integer
    add_column :journals,   :counterpart_id, :integer
    
    remove_column :outgoing_payment_modes, :position
    remove_column :incoming_payment_modes, :position
    
    add_column :land_parcels, :polygon, :string
    add_column :land_parcels, :parent_id, :integer
    add_column :land_parcels, :master, :boolean, :null=>false, :default=>false
    remove_column :land_parcels, :group_id
    # remove_column :land_parcels, :cultivation_id
    remove_column :land_parcels, :stopped_on
    remove_column :land_parcels, :started_on

    remove_column :operations, :production_chain_work_center_id

    rename_table :operation_uses, :tool_uses
    drop_table :production_chain_work_center_uses
    # drop_table :production_chain_work_center_lines
    drop_table :production_chain_work_centers
    # drop_table :production_chain_tokens
    drop_table :production_chain_conveyors
    drop_table :production_chains
    drop_table :tracking_states
    drop_table :cultivations
    drop_table :land_parcel_kinships
    drop_table :land_parcel_groups


    remove_column :transports, :amount_with_taxes
    remove_column :transports, :amount
    remove_column :transports, :purchase_order_id
    rename_column :subscriptions, :sales_order_line_id, :sale_order_line_id
    rename_column :subscriptions, :sales_order_id, :sale_order_id
    rename_column :subscriptions, :sales_invoice_id, :invoice_id
    remove_column :outgoing_delivery_modes, :with_transport
    rename_column :outgoing_deliveries, :sales_order_id, :order_id
    rename_column :outgoing_deliveries, :sales_invoice_id, :invoice_id
    remove_column :incoming_deliveries, :mode_id
    # change_column_null :incoming_deliveries, :purchase_order_id, true
    rename_column :incoming_deliveries, :purchase_order_id, :order_id
    rename_column :sales_invoice_lines, :sales_invoice_id, :invoice_id
    rename_column :sales_invoices, :sales_order_id, :sale_order_id


    for new, old in TABLES_UPDATES.reverse
      # Listings
      execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new}' WHERE attribute_name = '#{old}'"
      execute "UPDATE #{quoted_table_name(:listing_nodes)} SET attribute_name = '#{new.to_s.singularize}' WHERE attribute_name = '#{old.to_s.singularize}'"
      # Event natures
      execute "UPDATE #{quoted_table_name(:event_natures)} SET usage='#{new.to_s.singularize}' WHERE usage='#{old.to_s.singularize}'"
      # Document Templates
      execute "UPDATE #{quoted_table_name(:document_templates)} SET nature='#{new.to_s.singularize}' WHERE nature='#{old.to_s.singularize}'"
      execute "UPDATE #{quoted_table_name(:document_templates)} SET source=REPLACE(source, '#{old}', '#{new}'), cache=REPLACE(cache, '#{old}', '#{new}')"
      for table, column in POLYMORPHIC_COLUMNS.reverse
        execute "UPDATE #{quoted_table_name(table)} SET #{column}='#{new.to_s.classify}' WHERE #{column}='#{old.to_s.classify}'"
      end
    end
    # change_column :document_templates, :nature, :string, :limit=>64
    # change_column :event_natures, :usage, :string, :limit=>64
    for new, old in TABLES_UPDATES.reverse
      rename_table old, quoted_table_name(new)
    end
  end
end
