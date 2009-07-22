class Sep1b4 < ActiveRecord::Migration
  def self.up
    create_table :listings do |t|
      t.column :name,                   :string,   :null=>false
      t.column :root_model,             :string,   :null=>false
      t.column :query,                  :text
      t.column :comment,                :text
      t.column :company_id,             :integer,  :null=>false
    end

    create_table :listing_nodes do |t|
      t.column :name,                   :string,   :null=>false
      t.column :label,                  :string,   :null=>false
      t.column :nature,                 :string,   :null=>false
      t.column :reflection_name,        :string
      t.column :position,               :integer
      t.column :exportable,             :boolean,  :null=>false, :default=>true
      t.column :parent_id,              :integer
      t.column :comparator,             :string,   :limit=>16
      t.column :item_nature,            :string,   :limit=>8
      t.column :item_value,             :text
      t.column :item_listing_id,        :integer
      t.column :item_listing_node_id,   :integer
      t.column :listing_id,             :integer,  :null=>false
      t.column :company_id,             :integer,  :null=>false
    end

    create_table :listing_node_items do |t|
      t.column :node_id,                :integer,  :null=>false
      t.column :nature,                 :string,   :null=>false, :limit=>8
      t.column :value,                  :text
      t.column :company_id,             :integer,  :null=>false
    end

  end

  def self.down
    drop_table :listing_node_items
    drop_table :listing_nodes
    drop_table :listings
  end
end
