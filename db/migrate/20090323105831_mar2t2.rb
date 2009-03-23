class Mar2t2 < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :nature,            :string, :limit=>3
    add_column :stock_moves, :virtual,          :boolean, :null=>false
    add_column :sale_order_lines, :location_id, :integer, :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
    add_column :stock_moves, :input,            :boolean, :null=>false

    remove_column :deliveries, :delivered_on
    remove_column :deliveries, :shipped_on
    add_column :deliveries, :planned_on, :date, :null=>false
    add_column :deliveries, :moved_on,   :date

    create_table :products_stocks do |t|
      t.column :product_id,             :integer,  :null=>false, :references=>:products,  :on_delete=>:restrict, :on_update=>:restrict
      t.column :location_id,            :integer,  :null=>false, :references=>:stock_locations, :on_delete=>:restrict, :on_update=>:cascade
      t.column :current_real_quantity,       :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :current_virtual_quantity,    :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :quantity_min,           :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :critic_quantity_min,    :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :quantity_max,           :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade,  :on_update=>:cascade
    end
    add_index :products_stocks, :company_id


  end

  def self.down
    drop_table :products_stocks
    add_column :deliveries, :delivered_on, :date, :null=>false
    add_column :deliveries, :shipped_on, :date, :null=>false
    remove_column :deliveries, :planned_on 
    remove_column :deliveries, :moved_on
    remove_column :stock_moves, :input
    remove_column :sale_order_lines, :location_id
    remove_column :stock_moves, :virtual
    remove_column :deliveries, :nature
  end
end
