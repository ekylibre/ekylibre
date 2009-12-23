class CreateTrackingSupport < ActiveRecord::Migration
  def self.up
    add_column :stock_trackings, :product_id,  :integer, :references=>:products, :on_update=>:cascade, :on_delete=>:cascade
    add_column :stock_trackings, :producer_id, :integer, :references=>:entities, :on_update=>:cascade, :on_delete=>:cascade
    remove_column :stock_trackings, :begun_at

    add_column :product_stocks,  :origin_id,   :integer
    add_column :product_stocks,  :origin_type, :string   ## productions || purchase_orders || stock_transfers

    add_column :productions, :shape_id, :integer, :references=>:shapes
    
    add_column :products, :to_produce, :boolean, :null=>false, :default=>false
    execute "UPDATE products SET to_purchase=CAST('true' AS BOOLEAN) WHERE supply_method='buy'"
    execute "UPDATE products SET to_produce=CAST('true' AS BOOLEAN) WHERE supply_method='produce'"
    remove_column :products, :supply_method

    
    add_column :units, :start, :decimal, :null=>false, :default=>0.0
    rename_column :units, :quantity, :coefficient
    change_column :units, :coefficient, :decimal, :null=>false, :default=>1
    change_column :units, :base, :string, :null=>true
    execute "UPDATE units SET coefficient=coefficient/1000, base='kg' WHERE base='g'"
    execute "UPDATE units SET base='' WHERE base='u'"
    for unit in Unit.all
      unit.save
    end

    add_column :shapes, :number, :string
    add_column :shapes, :area_measure,   :decimal, :null=>false, :default=>0
    add_column :shapes, :area_unit_id,   :integer, :references=>:units
    for company in Company.all
      unit = company.units.find_by_base_and_coefficient_and_start('m2', 1, 0)
      unless unit
        company.load_units
        unit = company.units.find_by_base_and_coefficient_and_start('m2', 1, 0)
      end
      execute "UPDATE shapes SET area_unit_id=#{unit.id} WHERE company_id=#{company.id}"
    end

    add_column :sale_order_lines,     :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :purchase_order_lines, :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :product_stocks,       :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :stock_transfers,      :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :inventory_lines,      :tracking_id,     :integer,  :references=>:stock_trackings
    add_column :delivery_lines,       :tracking_id,     :integer,  :references=>:stock_trackings
    
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
    remove_column :delivery_lines,       :tracking_id
    remove_column :inventory_lines,      :tracking_id
    remove_column :stock_transfers,      :tracking_id
    remove_column :product_stocks,       :tracking_id
    remove_column :purchase_order_lines, :tracking_id
    remove_column :sale_order_lines,     :tracking_id
    
    remove_column :shapes, :area_unit_id
    remove_column :shapes, :area_measure
    remove_column :shapes, :number

    execute "UPDATE units SET label=label||' (ERROR)' WHERE start != 0"
    execute "UPDATE units SET base='u' WHERE LENGTH(TRIM(base))=0"
    rename_column :units, :coefficient, :quantity
    remove_column :units, :start

    add_column :products, :supply_method, :string, :null=>false, :default=>'buy'
    execute "UPDATE products SET supply_method='produce' WHERE to_produce"
    remove_column :products, :to_produce

    remove_column :productions, :shape_id

    remove_column :product_stocks, :origin_type
    remove_column :product_stocks, :origin_id

    add_column :stock_trackings, :begun_at, :datetime
    remove_column :stock_trackings, :producer_id
    remove_column :stock_trackings, :product_id
  end
end
