class CreateProductionChains < ActiveRecord::Migration
  def self.up

    create_table :land_parcel_groups do |t|
      t.column :name,             :string, :null=>false
      t.column :comment,          :text
      t.column :color,            :string, :limit=>6, :null=>false, :default=>"000000"
      # t.column :area_unit_id,     :integer, :null=>false
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
      t.column :production_chain_token_id, :integer
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


    create_table :production_chain_tokens do |t|
      t.column :production_chain_id, :integer, :null=>false
      t.column :number,           :string,   :null=>false
      t.column :where_id,         :integer,  :null=>false
      t.column :where_type,       :string,   :null=>false
      t.column :started_at,       :datetime, :null=>false
      t.column :stopped_at,       :datetime
      t.column :comment,          :text
      t.column :story,            :text
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_tokens, :company_id
    add_index :production_chain_tokens, [:production_chain_id, :company_id]
    add_index :production_chain_tokens, [:where_id, :where_type, :company_id]
    
    

    create_table :production_chain_operations do |t|
      t.column :production_chain_id, :integer, :null=>false
      t.column :operation_nature_id, :integer, :null=>false
      t.column :name,             :string,   :null=>false
      t.column :nature,           :string,   :null=>false # One in or One out
      t.column :building_id,      :integer,  :null=>false
      t.column :comment,          :text
      t.column :position,         :integer
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_operations, :company_id
    add_index :production_chain_operations, [:production_chain_id, :company_id]
    add_index :production_chain_operations, [:operation_nature_id, :company_id]


    create_table :production_chain_operation_lines do |t|
      t.column :operation_id,     :integer,  :null=>false
      t.column :from_operation_line_id, :integer, :null=>false
      t.column :direction,        :string,   :null=>false, :default=>"out"
      t.column :product_id,       :integer
      t.column :quantity,         :decimal,  :precision=>16, :scale=>4, :default=>0.0
      t.column :unit_id,          :integer
      t.column :warehouse_id,     :integer
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_operation_lines, :company_id
    add_index :production_chain_operation_lines, [:operation_id, :company_id]
    add_index :production_chain_operation_lines, [:operation_line_id, :company_id]

    create_table :production_chain_operation_uses do |t|
      t.column :operation_id,     :integer,  :null=>false
      t.column :tool_id,          :integer,  :null=>false
      t.column :company_id,       :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :production_chain_operation_uses, :company_id
    add_index :production_chain_operation_uses, [:operation_id, :company_id]


    rename_table :tool_uses, :operation_uses

    add_column :operations, :production_chain_token_id, :integer


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
    add_column :sale_payment_modes, :position, :integer, :null=>false, :default=>0
    execute "UPDATE #{quoted_table_name(:sale_payment_modes)} SET position = id"
    add_column :purchase_payment_modes, :position, :integer, :null=>false, :default=>0
    execute "UPDATE #{quoted_table_name(:purchase_payment_modes)} SET position = id"

    # Some accountancy stuff
    remove_column :journals,   :counterpart_id
    remove_column :warehouses, :account_id
    rename_column :taxes, :account_collected_id, :collected_account_id
    rename_column :taxes, :account_paid_id, :paid_account_id
  end

  def self.down
    rename_column :taxes, :paid_account_id, :account_paid_id
    rename_column :taxes, :collected_account_id, :account_collected_id
    add_column :warehouses, :account_id, :integer
    add_column :journals,   :counterpart_id, :integer
    
    remove_column :purchase_payment_modes, :position
    remove_column :sale_payment_modes, :position
    
    add_column :land_parcels, :polygon, :string
    add_column :land_parcels, :parent_id, :integer
    add_column :land_parcels, :master, :boolean, :null=>false, :default=>false
    remove_column :land_parcels, :group_id
    # remove_column :land_parcels, :cultivation_id
    remove_column :land_parcels, :stopped_on
    remove_column :land_parcels, :started_on

    remove_column :operations, :production_chain_token_id

    rename_table :operation_uses, :tool_uses
    drop_table :production_chain_operation_uses
    drop_table :production_chain_operation_lines
    drop_table :production_chain_operations
    drop_table :production_chain_tokens
    drop_table :production_chain_conveyors
    drop_table :production_chains
    drop_table :tracking_states
    drop_table :cultivations
    drop_table :land_parcel_kinships
    drop_table :land_parcel_groups
  end
end
