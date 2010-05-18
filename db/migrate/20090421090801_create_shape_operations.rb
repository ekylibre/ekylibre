class CreateShapeOperations < ActiveRecord::Migration
  def self.up
    add_column :sale_orders, :confirmed_on, :date
    execute "UPDATE sale_orders SET confirmed_on = current_date"
    execute "UPDATE sale_orders SET state = 'F'"

    create_table :shapes do |t|
      t.column :name,         :string,   :null=>false
      t.column :polygon,      :string,   :null=>false
      t.column :master,       :boolean,  :null=>false, :default=>true
      t.column :description,  :text
      t.column :parent_id,    :integer,                :references=>:shapes,    :on_delete=>:restrict, :on_update=>:restrict
      t.column :company_id,   :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    create_table :shape_operations do |t|
      t.column :name,         :string,   :null=>false
      t.column :description,  :text
      t.column :shape_id,     :integer,  :null=>false, :references=>:shapes,    :on_delete=>:restrict, :on_update=>:restrict
      t.column :employee_id,  :integer,  :null=>false, :references=>:employees, :on_delete=>:restrict, :on_update=>:restrict
      t.column :nature_id,    :integer,                :references=>:shape_operation_natures, :on_delete=>:restrict, :on_update=>:restrict
      t.column :planned_on,   :date,     :null=>false
      t.column :moved_on,     :date
      t.column :started_at,   :timestamp,:null=>false
      t.column :stopped_at,   :timestamp
      t.column :company_id,   :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    create_table :shape_operation_natures do |t|
      t.column :name, :string, :null=>false
      t.column :description, :text
      t.column :company_id,  :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    

  end
  
  def self.down
    drop_table :shape_operation_natures
    drop_table :shape_operations
    drop_table :shapes
    remove_column :sale_orders, :confirmed_on
  end
end
