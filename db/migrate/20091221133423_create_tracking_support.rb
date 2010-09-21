class CreateTrackingSupport < ActiveRecord::Migration
  ACCOUNTED_TABLES = [:invoices, :payments, :purchase_orders, :sale_orders, :transfers]

  def self.up
    for table in ACCOUNTED_TABLES
      add_column table, :accounted_at, :datetime
      add_index table, :accounted_at
      execute "UPDATE #{quote_table_name(table)} SET accounted_at=updated_at WHERE accounted=#{quoted_true}"
      remove_column table, :accounted
    end

    add_column :stock_trackings, :product_id,  :integer, :references=>:products, :on_update=>:cascade, :on_delete=>:cascade
    add_column :stock_trackings, :producer_id, :integer, :references=>:entities, :on_update=>:cascade, :on_delete=>:cascade
    remove_column :stock_trackings, :begun_at

    add_column :product_stocks,  :origin_id,   :integer
    add_column :product_stocks,  :origin_type, :string   ## productions OR purchase_orders OR stock_transfers

    add_column :productions, :shape_id, :integer, :references=>:shapes
    
    add_column :products, :to_produce, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quote_table_name(:products)} SET to_purchase=#{quoted_true} WHERE supply_method='buy'"
    execute "UPDATE #{quote_table_name(:products)} SET to_produce=#{quoted_true} WHERE supply_method='produce'"
    remove_column :products, :supply_method

    add_column :units, :start, :decimal, :null=>false, :default=>0.0
    rename_column :units, :quantity, :coefficient
    change_column :units, :coefficient, :decimal, :null=>false, :default=>1
    change_column :units, :base, :string, :null=>true
    execute "UPDATE #{quote_table_name(:units)} SET coefficient=coefficient/1000, base='kg' WHERE base='g'"
    execute "UPDATE #{quote_table_name(:units)} SET base='' WHERE base='u'"
    if defined? Unit
      for unit in Unit.all
        unit.save
      end
    end

    add_column :shapes, :number, :string
    add_column :shapes, :area_measure,   :decimal, :null=>false, :default=>0
    add_column :shapes, :area_unit_id,   :integer, :references=>:units

    add_column :purchase_order_lines, :annotation,      :text
    add_column :purchase_orders,      :currency_id,     :integer

    companies = connection.select_all "SELECT * FROM #{quote_table_name(:companies)}"
    if companies.size > 0
      execute "INSERT INTO #{quote_table_name(:units)} (name, base, coefficient, start, company_id, created_at, updated_at) SELECT 'm²', 'm2', 1, 0, id, created_at, updated_at FROM #{quote_table_name(:companies)} WHERE id NOT IN (SELECT company_id FROM #{quote_table_name(:units)} WHERE base='m2' AND start=0 AND coefficient=1)"
      units = "SELECT * FROM #{quote_table_name(:units)} WHERE base='m2' AND start=0 AND coefficient=1"
      execute "UPDATE #{quote_table_name(:shapes)} SET area_unit_id=CASE "+units.collect{|u| "WHEN company_id=#{u['company_id']} THEN #{u['id']}"}+" ELSE 0 END"
      currencies = "SELECT * FROM #{quote_table_name(:currencies)}"
      execute "UPDATE #{quote_table_name(:purchase_orders)} SET currency_id=CASE "+currencies.collect{|c| "WHEN company_id=#{c['company_id']} THEN #{c['id']}"}+" ELSE 0 END"
    end
        
    add_column :sale_order_lines,     :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :purchase_order_lines, :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :product_stocks,       :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :stock_transfers,      :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :inventory_lines,      :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :delivery_lines,       :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :productions,          :tracking_id,     :integer,  :references=>:stock_trackings

    add_column :purchase_order_lines, :tracking_serial, :string
    add_column :productions,          :tracking_serial, :string
    
    create_table :shape_operation_lines do |t|
      t.column :shape_operation_id,     :integer,   :null=>false, :references=>:shape_operations, :on_delete=>:cascade, :on_update=>:cascade
      t.column :product_id,             :integer,   :references=>:products
      t.column :unit_quantity,          :decimal,   :null=>false, :default=>0
      t.column :quantity,               :decimal,   :null=>false, :default=>0
      t.column :product_unit_id,        :integer,   :references=>:units
      t.column :area_unit_id,           :integer,   :references=>:units
      t.column :tracking_id,            :integer,   :references=>:stock_trackings
      t.column :company_id,             :integer,   :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end

  end

  def self.down
    drop_table :shape_operation_lines

    remove_column :productions,          :tracking_serial
    remove_column :purchase_order_lines, :tracking_serial

    remove_column :productions,          :tracking_id
    remove_column :delivery_lines,       :tracking_id
    remove_column :inventory_lines,      :tracking_id
    remove_column :stock_transfers,      :tracking_id
    remove_column :product_stocks,       :tracking_id
    remove_column :purchase_order_lines, :tracking_id
    remove_column :sale_order_lines,     :tracking_id

    remove_column :purchase_orders,      :currency_id
    remove_column :purchase_order_lines, :annotation

    
    remove_column :shapes, :area_unit_id
    remove_column :shapes, :area_measure
    remove_column :shapes, :number

    execute "UPDATE #{quote_table_name(:units)} SET label="+connection.concatenate("label", "' (ERROR)'")+" WHERE start != 0"
    execute "UPDATE #{quote_table_name(:units)} SET base='u' WHERE "+connection.length(connection.trim("base"))+"=0"
    rename_column :units, :coefficient, :quantity
    remove_column :units, :start

    add_column :products, :supply_method, :string, :null=>false, :default=>'buy'
    execute "UPDATE #{quote_table_name(:products)} SET supply_method='produce' WHERE to_produce"
    remove_column :products, :to_produce

    remove_column :productions, :shape_id

    remove_column :product_stocks, :origin_type
    remove_column :product_stocks, :origin_id

    add_column :stock_trackings, :begun_at, :datetime
    remove_column :stock_trackings, :producer_id
    remove_column :stock_trackings, :product_id


    for table in ACCOUNTED_TABLES.reverse
      add_column table, :accounted, :boolean, :null=>false, :default=>false
      add_index table, :accounted
      execute "UPDATE #{quote_table_name(table)} SET accounted=#{quoted_true} WHERE accounted_at IS NOT NULL"
      remove_column table, :accounted_at
    end
  end
end
