class CreateEntityLinks < ActiveRecord::Migration
  def self.up
    create_table :entity_link_natures do |t|
      t.column :name,            :string,   :null=>false
      t.column :name_1_to_2,     :string
      t.column :name_2_to_1,     :string
      t.column :symmetric,       :boolean,  :null=>false, :default=>false   
      t.column :company_id,      :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_stamps :entity_link_natures
    add_index :entity_link_natures, :company_id
    add_index :entity_link_natures, :name    
    add_index :entity_link_natures, :name_1_to_2
    add_index :entity_link_natures, :name_2_to_1 
    
    create_table :entity_links do |t|
      t.column :entity1_id,      :integer,  :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
      t.column :entity2_id,      :integer,  :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
      t.column :nature_id,       :integer,  :null=>false, :references=>:entity_link_natures, :on_delete=>:cascade, :on_update=>:cascade
      t.column :started_on,      :date
      t.column :stopped_on,      :date
      t.column :comment,         :text
      t.column :company_id,      :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_stamps :entity_links

    add_index :entity_links, :company_id
    add_index :entity_links, :nature_id
    add_index :entity_links, :entity1_id
    add_index :entity_links, :entity2_id
  end

  def self.down
    drop_table :entity_links
    drop_table :entity_link_natures
  end
end
