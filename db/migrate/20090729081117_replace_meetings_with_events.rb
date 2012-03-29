class ReplaceMeetingsWithEvents < ActiveRecord::Migration
  def self.up

    remove_column :entities,  :origin_id
    add_column :entities,     :origin,  :string
    
    create_table :event_natures do |t|
      t.column :name,         :string,  :null=>false
      t.column :duration,     :integer
      t.column :company_id,   :integer, :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :event_natures
    add_index :event_natures, :company_id
    add_index :event_natures, :name

    create_table :events do |t|
      t.column :location,     :string
      t.column :duration,     :integer
      t.column :started_at,   :timestamp, :null=>false
      t.column :started_sec,  :integer,   :null=>false
      t.column :reason,       :text
      t.column :entity_id,    :integer, :null=>false, :references=>:entities, :on_delete=>:restrict, :on_update=>:restrict
      t.column :nature_id,    :integer, :null=>false, :references=>:event_natures, :on_delete=>:restrict, :on_update=>:restrict 
      t.column :employee_id,  :integer, :null=>false, :references=>:employees, :on_delete=>:restrict, :on_update=>:restrict
      t.column :company_id,   :integer, :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :events
    add_index :events, :company_id
    add_index :events, :entity_id
    add_index :events, :nature_id
    add_index :events, :employee_id
    

    drop_table :meetings
    drop_table :meeting_modes
    drop_table :meeting_locations
        
  end




  def self.down

     create_table :meeting_locations do |t|
      t.column :name,        :string,   :null=>false
      t.column :description, :text
      t.column :active,      :boolean
      t.column :company_id,  :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :meeting_locations

    create_table :meeting_modes do |t|
      t.column :name,        :string,    :null=>false
      t.column :active,      :boolean
      t.column :company_id,  :integer,   :null=>false, :references=>:companies,:on_delete=>:restrict, :on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :meeting_modes

    create_table :meetings do |t|
      t.column :entity_id,    :integer,  :null=>false,  :references=>:entities,:on_delete=>:restrict, :on_update=>:restrict
      t.column :location_id,  :integer,  :null=>false,  :references=>:meeting_locations,  :on_delete=>:restrict, :on_update=>:restrict
      t.column :employee_id,  :integer,  :null=>false,  :references=>:employees,:on_delete=>:restrict,:on_update=>:restrict
      t.column :mode_id,      :integer,  :null=>false,  :references=>:meeting_modes, :on_delete=>:restrict, :on_update=>:restrict
      t.column :taken_place_on, :date,     :null=>false
      t.column :address,      :text
      t.column :description,  :text
      t.column :company_id,   :integer,  :null=>false,  :references=>:companies,:on_delete=>:restrict,:on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :meetings
    
    drop_table    :events
    drop_table    :event_natures
        
    remove_column :entities, :origin
    add_column    :entities,  :origin_id,    :integer, :references=>:meeting_locations, :on_delete=>:restrict, :on_update=>:restrict

  end
end
