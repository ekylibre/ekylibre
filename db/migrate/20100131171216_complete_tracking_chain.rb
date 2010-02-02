class CompleteTrackingChain < ActiveRecord::Migration
  QTY_COLUMNS = [ [:complement_data, :decimal_value], [:deliveries, :weight], [:delivery_lines, :quantity], [:inventory_lines, :quantity], [:inventory_lines, :theoric_quantity], [:invoice_lines, :quantity], [:locations, :quantity_max], [:operations, :consumption], [:operations, :duration], [:operations, :hour_duration], [:operations, :min_duration], [:operation_lines, :quantity], [:operation_lines, :unit_quantity], [:parameters, :decimal_value], [:prices, :quantity_max], [:prices, :quantity_min], [:products, :critic_quantity_min], [:products, :quantity_max], [:products, :quantity_min], [:products, :service_coeff], [:product_components, :quantity], [:productions, :quantity], [:purchase_order_lines, :quantity], [:sale_order_lines, :quantity], [:shapes, :area_measure], [:stocks, :critic_quantity_min], [:stocks, :quantity], [:stocks, :quantity_max], [:stocks, :quantity_min], [:stocks, :virtual_quantity], [:stock_moves, :quantity], [:stock_transfers, :quantity], [:subscriptions, :quantity], [:tools, :consumption], [:transports, :weight], [:units, :coefficient], [:units, :start], [:users, :reduction_percent] ]

  def self.sqlint(val)
    if val.nil?
      return " IS NULL"
    else
      return "="+val.to_s
    end
  end

  def self.up
    rename_table :product_stocks,          :stocks 
    rename_table :shape_operations,        :operations
    rename_table :shape_operation_natures, :operation_natures
    rename_table :shape_operation_lines,   :operation_lines
    rename_table :stock_trackings,         :trackings
    rename_table :stock_locations,         :locations

    add_column    :delivery_lines,    :location_id,              :integer
    rename_column :inventory_lines,   :validated_quantity,       :quantity
    add_column    :inventory_lines,   :unit_id,                  :integer
    add_column    :invoice_lines,     :unit_id,                  :integer
    add_column    :invoice_lines,     :tracking_id,              :integer
    add_column    :invoice_lines,     :location_id,              :integer
    add_column    :operations,        :target_type,              :string
    add_column    :operations,        :target_id,                :integer 
    execute "UPDATE operations SET target_type='Shape', target_id=shape_id"
    remove_column :operations,        :shape_id
    rename_column :operation_lines,   :shape_operation_id,       :operation_id
    rename_column :operation_lines,   :product_unit_id,          :unit_id
    add_column    :operation_lines,   :location_id,              :integer
    add_column    :operation_lines,   :direction,                :string, :null=>false, :default=>"in", :limit=>4
    add_column    :operation_lines,   :tracking_serial,          :string
    add_column    :operation_natures, :target_type,              :string
    execute "UPDATE operation_natures SET target_type='Shape'"
    add_column    :stock_transfers,   :unit_id,                  :integer
    rename_column :stocks,            :current_real_quantity,    :quantity
    rename_column :stocks,            :current_virtual_quantity, :virtual_quantity
    add_column    :stocks,            :name,                     :string
    add_column    :stocks,            :unit_id,                  :integer
    add_column    :stock_moves,       :stock_id,                 :integer
    for stock in select_all("SELECT id, location_id AS lid, product_id AS pid, tracking_id AS tid, company_id AS cid FROM stocks")
      execute "UPDATE stock_moves SET stock_id=#{stock['id']} WHERE location_id#{sqlint(stock['lid'])} AND product_id#{sqlint(stock['pid'])} AND tracking_id#{sqlint(stock['pid'])} AND company_id#{sqlint(stock['cid'])}"
    end
    execute "UPDATE stock_moves SET quantity = CASE WHEN input THEN quantity ELSE -quantity END"
    remove_column :stock_moves,       :input
    rename_column :tool_uses,         :shape_operation_id,       :operation_id


    if adapter_name == "PostgreSQL"
      execute "UPDATE delivery_lines SET location_id = sol.location_id FROM sale_order_lines AS sol WHERE order_line_id=delivery_lines.id"
      execute "UPDATE invoice_lines  SET location_id = sol.location_id, tracking_id=sol.tracking_id, unit_id=sol.unit_id FROM sale_order_lines AS sol WHERE order_line_id=invoice_lines.id"
      execute "UPDATE inventory_lines SET unit_id=p.unit_id FROM products AS p WHERE p.id=product_id AND inventory_lines.unit_id IS NULL"
      execute "UPDATE operation_lines SET unit_id=p.unit_id FROM products AS p WHERE p.id=product_id AND operation_lines.unit_id IS NULL"
      execute "UPDATE stock_transfers SET unit_id=p.unit_id FROM products AS p WHERE p.id=product_id AND stock_transfers.unit_id IS NULL"
      execute "UPDATE stocks          SET unit_id=p.unit_id FROM products AS p WHERE p.id=product_id AND stocks.unit_id IS NULL"
    else
      for line in select_all("SELECT * FROM sale_order_lines")
        id, unit_id, location_id, tracking_id = line['id'], line['unit_id'], line['location_id'], line['tracking_id']
        execute "UPDATE delivery_lines SET location_id=#{location_id} WHERE order_line_id=#{id}"
        execute "UPDATE invoice_lines  SET unit_id=#{unit_id}, location_id=#{location_id}, tracking_id=#{tracking_id} WHERE order_line_id=#{id}"
      end
      for product in select_all("SELECT * FROM products")
        id, unit_id = product['id'], product['unit_id']
        execute "UPDATE inventory_lines SET unit_id=#{unit_id} WHERE unit_id IS NULL AND product_id=#{id}"
        execute "UPDATE operation_lines SET unit_id=#{unit_id} WHERE unit_id IS NULL AND product_id=#{id}"
        execute "UPDATE stock_transfers SET unit_id=#{unit_id} WHERE unit_id IS NULL AND product_id=#{id}"
        execute "UPDATE stocks          SET unit_id=#{unit_id} WHERE unit_id IS NULL AND product_id=#{id}"
      end
    end

    # normalize quantity columns in precision 16 and scale 4
    for table, column in QTY_COLUMNS
      change_column table, column, :decimal, :precision=>16, :scale=>4
    end

    for production in select_all("SELECT * from productions")
      id = production['id']
      operation_id = insert("INSERT INTO operations (company_id, created_at, creator_id, moved_on, name, planned_on, responsible_id, started_at, target_type, target_id, updated_at, updater_id) SELECT company_id, created_at, creator_id, moved_on, COALESCE(tracking_serial, 'Production'), planned_on, creator_id, created_at, 'Shape', shape_id, updated_at, updater_id FROM productions WHERE id=#{id}")
      insert("INSERT INTO operation_lines (company_id, created_at, creator_id, direction, location_id, operation_id, product_id, quantity, tracking_id, tracking_serial, unit_id, updated_at, updater_id) SELECT p.company_id, p.created_at, p.creator_id, 'out', p.location_id, #{operation_id}, p.product_id, p.quantity, p.tracking_id, p.tracking_serial, pc.unit_id, p.updated_at, p.updater_id FROM productions AS p LEFT JOIN products AS pc ON (p.product_id=pc.id) WHERE p.id=#{id}")
    end

    drop_table :productions

    execute "UPDATE parameters SET name='management.invoices.numeration' where name='management.invoicing.numeration'"
  end

  def self.down
    execute "UPDATE parameters SET name='management.invoicing.numeration' where name='management.invoices.numeration'"

    create_table :productions do |t|
      t.integer  "product_id",                                                      :null => false
      t.decimal  "quantity",        :precision => 16, :scale => 4, :default => 0.0, :null => false
      t.integer  "location_id",                                                     :null => false
      t.date     "planned_on",                                                      :null => false
      t.date     "moved_on"
      t.integer  "company_id",                                                      :null => false
      t.datetime "created_at",                                                      :null => false
      t.datetime "updated_at",                                                      :null => false
      t.integer  "creator_id"
      t.integer  "updater_id"
      t.integer  "lock_version",                                   :default => 0,   :null => false
      t.integer  "shape_id"
      t.integer  "tracking_id"
      t.string   "tracking_serial"
    end

    execute "INSERT INTO productions (product_id, quantity, location_id, planned_on, moved_on, company_id, created_at, updated_at, creator_id, updater_id, shape_id, tracking_id, tracking_serial) SELECT ol.product_id, ol.quantity, ol.location_id, o.planned_on, o.moved_on, o.company_id, o.created_at, o.updated_at, o.creator_id, o.updater_id, CASE WHEN target_type='Shape' THEN o.target_id ELSE NULL END, ol.tracking_id, ol.tracking_serial FROM operation_lines AS ol JOIN operations AS o ON (ol.operation_id=o.id) WHERE direction='out'"
    execute "DELETE FROM operation_lines WHERE direction='out'"
    execute "DELETE FROM operations WHERE id NOT IN (SELECT operation_id FROM operation_lines)"

    # Skip denormalization of quantity columns (unecessary)

    rename_column :tool_uses,         :operation_id,     :shape_operation_id
    add_column    :stock_moves,       :input,            :boolean, :null=>false, :default=>false
    execute "UPDATE stock_moves SET input=(quantity>=0), quantity = ABS(quantity)"
    remove_column :stock_moves,       :stock_id
    remove_column :stocks,            :unit_id
    remove_column :stocks,            :name
    rename_column :stocks,            :quantity,         :current_real_quantity
    rename_column :stocks,            :virtual_quantity, :current_virtual_quantity
    remove_column :stock_transfers,   :unit_id
    remove_column :operation_natures, :target_type
    remove_column :operation_lines,   :tracking_serial
    remove_column :operation_lines,   :direction
    remove_column :operation_lines,   :location_id
    rename_column :operation_lines,   :unit_id,          :product_unit_id
    rename_column :operation_lines,   :operation_id,     :shape_operation_id
    add_column    :operations,        :shape_id,         :integer
    execute "UPDATE operations SET shape_id=target_id WHERE target_type='Shape'"
    execute "DELETE FROM operations WHERE shape_id IS NULL"
    remove_column :operations,        :target_id
    remove_column :operations,        :target_type
    remove_column :invoice_lines,     :location_id
    remove_column :invoice_lines,     :tracking_id
    remove_column :invoice_lines,     :unit_id
    remove_column :inventory_lines,   :unit_id
    rename_column :inventory_lines,   :quantity,         :validated_quantity
    remove_column :delivery_lines,    :location_id

    rename_table :locations,         :stock_locations
    rename_table :trackings,         :stock_trackings
    rename_table :operation_lines,   :shape_operation_lines
    rename_table :operation_natures, :shape_operation_natures
    rename_table :operations,        :shape_operations
    rename_table :stocks,            :product_stocks 
  end
end
