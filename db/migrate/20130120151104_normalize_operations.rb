class NormalizeOperations < ActiveRecord::Migration
  def up
    # Normalize existing operation_natures
    remove_column :operation_natures, :target_type
    add_column :operation_natures, :transferable, :boolean, :null => false

    # Normalize existing operations
    remove_column :operations, :consumption
    execute("UPDATE #{quoted_table_name(:operations)} SET started_at = COALESCE(moved_on, planned_on)")
    remove_column :operations, :moved_on
    remove_column :operations, :planned_on
    execute("UPDATE #{quoted_table_name(:operations)} SET stopped_at = started_at + CAST(CAST(duration AS VARCHAR)||' minutes' AS INTERVAL)")
    remove_column :operations, :duration
    remove_column :operations, :hour_duration
    remove_column :operations, :min_duration
    rename_column :operations, :description, :comment

    # Normalize existing operation items
    remove_column :operation_items, :area_unit_id
    remove_column :operation_items, :unit_quantity
    rename_column :operation_items, :tracking_serial, :serial_number
    rename_column :operation_items, :direction, :usage
    change_column :operation_items, :usage, :string, :limit => 32, :null => false, :default => nil
    execute "UPDATE #{quoted_table_name(:operation_items)} SET usage = CASE WHEN usage = 'in' THEN 'input' ELSE 'output' END"
    
    # Set product(nature) utilizable
    add_column :product_natures, :utilizable, :boolean, :null => false, :default => false
    execute "UPDATE #{quoted_table_name(:product_natures)} SET utilizable = #{quoted_true} FROM #{quoted_table_name(:product_varieties)} AS v WHERE variety_id = v.id AND product_type = 'Tool'"

    # Tools
    ca = [:operation_id, :created_at, :creator_id, :lock_version, :updated_at, :updater_id]
    da = {:usage => "'tool'", :product_id => :tool_id}
    execute "INSERT INTO #{quoted_table_name(:operation_items)} (" + ca.join(", ") + ", " + da.join(", ") + ") SELECT " + ca.join(", ") + ", " + da.join(", ") + " FROM #{quoted_table_name(:operation_uses)} AS ou"
    remove_column :operations, :tools_list

    # Target(s)
    ca = [:created_at, :creator_id, :lock_version, :updated_at, :updater_id]
    da = {:operation_id => :id, :usage => "'target'", :product_id => :target_id}
    execute "INSERT INTO #{quoted_table_name(:operation_items)} (" + ca.join(", ") + ", " + da.join(", ") + ") SELECT " + ca.join(", ") + ", " + da.join(", ") + " FROM #{quoted_table_name(:operations)} AS o"
    remove_column :operations, :target_type
    remove_column :operations, :target_id

    # Workers
    create_table :operation_jobs do |t|
      t.belongs_to :operation, :null => false
      t.belongs_to :worker, :null => false
      t.stamps
    end
    add_stamps_indexes :operation_jobs
    add_index :operation_jobs, :operation_id
    add_index :operation_jobs, :worker_id

    ca = [:created_at, :creator_id, :lock_version, :updated_at, :updater_id]
    da = {:operation_id => :id, :worker_id => :responsible_id}
    execute "INSERT INTO #{quoted_table_name(:operation_jobs)} (" + ca.join(", ") + ", " + da.join(", ") + ") SELECT " + ca.join(", ") + ", " + da.join(", ") + " FROM #{quoted_table_name(:operations)} AS o"
    remove_column :operations, :responsible_id

    # 
    


    drop_table :operation_uses
  end

  def down
  end
end
