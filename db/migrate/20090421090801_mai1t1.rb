class Mai1t1 < ActiveRecord::Migration
  def self.up
    add_column :sale_orders, :confirmed_on, :date
    execute "UPDATE sale_orders SET state = 'F'"
       
    create_table :shapes do |t|
      t.column :polygon,      :string
      t.column :master,       :boolean,  :null=>false, :default=>true
      t.column :description,  :string
      t.column :shape_id,     :integer,                :references=>:shapes,    :on_delete=>:restrict, :on_update=>:restrict
      t.column :company_id,   :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    create_table :shape_operations do |t|
      t.column :shape_id,     :integer,  :null=>false, :references=>:shapes,    :on_delete=>:restrict, :on_update=>:restrict
      t.column :employee_id,  :integer,  :null=>false, :references=>:employees, :on_delete=>:restrict, :on_update=>:restrict
      t.column :planned_on,   :date,     :null=>false
      t.column :moved_on,     :date
      t.column :started_at,   :timestamp,:null=>false
      t.column :stopped_at,   :timestamp
      t.column :company_id,   :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

  end

  def self.down
    drop_table :shape_operations
    drop_table :shapes
    remove_column :sale_orders, :confirmed_on
  end
end
