class AddMaterialProduction < ActiveRecord::Migration
  def self.up

    create_table :tools do |t|
      t.column :name,            :string,   :null=>false
      t.column :nature,          :string,   :null=>false, :limit=>8   ## tractor, towed, other
      t.column :consumption,     :decimal
      t.column :company_id,      :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end

    add_column :shape_operations, :hour_duration, :decimal
    add_column :shape_operations, :min_duration,  :decimal
    add_column :shape_operations, :duration,      :decimal
    add_column :shape_operations, :consumption,   :decimal        

    create_table :shape_operations_tools do |t|
      t.column :shape_operation_id,  :integer,  :null=>false, :references=>:shape_operations, :on_delete=>:cascade, :on_update=>:cascade
      t.column :tool_id,             :integer,  :null=>false, :references=>:tools, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,          :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    

  end

  def self.down
    drop_table :shape_operations_tools
    remove_column :shape_operations, :consumption
    remove_column :shape_operations, :duration
    remove_column :shape_operations, :min_duration
    remove_column :shape_operations, :hour_duration
    drop_table :tools
  end
end
