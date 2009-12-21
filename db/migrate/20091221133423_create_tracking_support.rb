class CreateTrackingSupport < ActiveRecord::Migration
  def self.up
    add_column :stock_trackings, :product_id,  :integer, :references=>:products, :on_update=>:cascade, :on_delete=>:cascade
    add_column :stock_trackings, :producer_id, :integer, :references=>:entities, :on_update=>:cascade, :on_delete=>:cascade
    remove_column :stock_trackings, :begun_at

    add_column :product_stocks,  :origin_id,   :integer
    add_column :product_stocks,  :origin_type, :string   ## productions || purchase_orders || stock_transfers

    add_column :productions, :shape_id, :integer, :references=>:shapes
    
    add_column :products, :to_produce, :boolean, :null=>false, :default=>false


    add_column :units, :expression, :string
    add_column :units, :normalized_expression, :string
    execute "UPDATE units SET quantity=quantity/1000, base='kg' WHERE base='g'"
    execute "UPDATE units SET expression=CAST(quantity AS VARCHAR)||' '||base"
    for unit in Unit.all
      unit.save
    end
    remove_column :units, :quantity
    remove_column :units, :base

    add_column :shapes, :number, :string
    add_column :shapes, :area,   :decimal, :null=>false, :default=>0
#    add_column :shapes, :area_unit_id, :integer, :references=>:units

    add_column :sale_order_lines,     :tracking_id,     :integer,  :references=>:stock_trackings, :on_delete=>:cascade, :on_update=>:cascade
    add_column :purchase_order_lines, :tracking_id,     :integer,  :references=>:stock_trackings, :on_delete=>:cascade, :on_update=>:cascade
    add_column :product_stocks,       :tracking_id,     :integer,  :references=>:stock_trackings, :on_update=>:cascade, :on_delete=>:cascade 
    add_column :stock_transfers,      :tracking_id,     :integer,  :references=>:stock_trackings, :on_update=>:cascade, :on_delete=>:cascade 
    add_column :inventory_lines,      :tracking_id,     :integer,  :references=>:stock_trackings, :on_update=>:cascade, :on_delete=>:cascade 
    add_column :delivery_lines,       :tracking_id,     :integer,  :references=>:stock_trackings, :on_update=>:cascade, :on_delete=>:cascade 
    
    create_table :shape_operation_lines do |t|
      t.column :shape_operation_id,     :integer,   :null=>false, :references=>:shape_operations, :on_delete=>:cascade, :on_update=>:cascade
      t.column :product_id,             :integer,   :references=>:products
      t.column :quantity,               :decimal
      t.column :surface_unit_id,        :integer,   :references=>:units
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
    
    add_column :units, :base,     :string
    add_column :units, :quantity, :decimal, :null=>false, :default=>1
    execute "UPDATE units SET base=expression, quantity=1"
    remove_column :units, :expression
    remove_column :units, :normalized_expression

    remove_column :shapes, :area
    remove_column :shapes, :number
    remove_column :products, :to_produce
    remove_column :productions, :shape_id
    remove_column :product_stocks, :origin_type
    remove_column :product_stocks, :origin_id
    add_column :stock_trackings, :begun_at, :datetime
    remove_column :stock_trackings, :producer_id
    remove_column :stock_trackings, :product_id
  end
end
