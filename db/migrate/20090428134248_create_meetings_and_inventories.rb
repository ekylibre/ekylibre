class CreateMeetingsAndInventories < ActiveRecord::Migration
  def self.up

    create_table :meeting_locations do |t|
      t.column :name,        :string,   :null=>false
      t.column :description, :text
      t.column :active,      :boolean
      t.column :company_id,  :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    create_table :meeting_modes do |t|
      t.column :name,        :string,    :null=>false
      t.column :active,      :boolean
      t.column :company_id,  :integer,   :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    create_table :meetings do |t|
      t.column :entity_id,    :integer,  :null=>false,  :references=>:entities,  :on_delete=>:restrict, :on_update=>:restrict
      t.column :location_id,  :integer,  :null=>false,  :references=>:meeting_locations,  :on_delete=>:restrict, :on_update=>:restrict
      t.column :employee_id,  :integer,  :null=>false,  :references=>:employees, :on_delete=>:restrict, :on_update=>:restrict
      t.column :mode_id,      :integer,  :null=>false,  :references=>:meeting_modes, :on_delete=>:restrict, :on_update=>:restrict
      t.column :taken_place_on, :date,     :null=>false
      t.column :address,      :text
      t.column :description,  :text
      t.column :company_id,   :integer,  :null=>false,  :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    create_table :stock_transfers do |t|
      t.column :nature,       :string,   :null=>false,  :limit=>8     ## "Transfer"  "Waste" 
      t.column :product_id,   :integer,  :null=>false,  :references=>:products,        :on_delete=>:restrict, :on_update=>:restrict 
      t.column :quantity,     :float,    :null=>false
      t.column :location_id,  :integer,  :null=>false,  :references=>:stock_locations, :on_delete=>:restrict, :on_update=>:restrict 
      t.column :second_location_id,      :integer,      :references=>:stock_locations, :on_delete=>:restrict, :on_update=>:restrict 
      t.column :planned_on,   :date,     :null=>false
      t.column :moved_on,     :date
      t.column :comment,      :text
      t.column :company_id,   :integer,  :null=>false,  :references=>:companies,       :on_delete=>:restrict, :on_update=>:restrict 
    end

    create_table :inventories do |t|
      t.column :date,         :date,     :null=>false
      t.column :comment,      :text
      t.column :changes_reflected,       :boolean 
      t.column :company_id,   :integer,  :null=>false,  :references=>:companies,       :on_delete=>:restrict, :on_update=>:restrict 
    end

    create_table :inventory_lines do |t|
      t.column :product_id,       :integer,  :null=>false,  :references=>:products,       :on_delete=>:restrict, :on_update=>:restrict 
      t.column :location_id,      :integer,  :null=>false,  :references=>:stock_locations, :on_delete=>:restrict, :on_update=>:restrict 
      t.column :theoric_quantity, :decimal,  :null=>false, :precision=>16, :scale=>2
      t.column :validated_quantity,:decimal, :null=>false, :precision=>16, :scale=>2
      t.column :inventory_id,     :integer,  :null=>false,  :references=>:inventories,     :on_delete=>:restrict, :on_update=>:restrict 
      t.column :company_id,       :integer,  :null=>false,  :references=>:companies,       :on_delete=>:restrict, :on_update=>:restrict 
    end

    add_column :stock_locations,  :reservoir,   :boolean, :default=>false
    add_column :stock_locations,  :product_id,  :integer, :references=>:products,  :on_delete=>:restrict, :on_update=>:restrict
    add_column :stock_locations,  :quantity_max,:float
    add_column :stock_locations,  :unit_id,     :integer, :references=>:units, :on_delete=>:cascade, :on_update=>:cascade
    add_column :stock_locations,  :number,      :integer

    add_column :entities,     :origin_id,    :integer, :references=>:meeting_locations, :on_delete=>:restrict, :on_update=>:restrict
    add_column :entities,     :first_met_on, :date

    execute "INSERT INTO meeting_locations(company_id, name, active,  created_at, updated_at) SELECT companies.id, 'Divers', #{quoted_true},  current_timestamp, current_timestamp FROM companies LEFT JOIN meeting_locations ml ON (ml.company_id=companies.id AND ml.name='Divers') WHERE ml.id IS NULL"

    execute "INSERT INTO meeting_modes(company_id, name, active,  created_at, updated_at) SELECT companies.id, 'En personne', #{quoted_true},  current_timestamp, current_timestamp FROM companies LEFT JOIN meeting_modes mm ON (mm.company_id=companies.id AND mm.name='En personne') WHERE mm.id IS NULL"

  end


  def self.down
    remove_column :entities, :first_met_on
    remove_column :entities, :origin_id
    remove_column :stock_locations, :number
    remove_column :stock_locations, :unit_id
    remove_column :stock_locations, :quantity_max
    remove_column :stock_locations, :product_id
    remove_column :stock_locations, :reservoir
    drop_table :inventory_lines
    drop_table :inventories
    drop_table :stock_transfers
    drop_table :meetings
    drop_table :meeting_modes
    drop_table :meeting_locations

  end

end
