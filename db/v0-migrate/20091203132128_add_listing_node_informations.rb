class AddListingNodeInformations < ActiveRecord::Migration
  def self.up

    add_column :listing_nodes, :key, :string
    add_column :listing_nodes, :sql_type, :string
    add_column :listing_nodes, :condition_value, :string
    add_column :listing_nodes, :condition_operator, :string
    add_column :listing_nodes, :attribute_name, :string
    remove_column :listing_nodes, :reflection_name
    remove_column :listing_nodes, :comparator
    add_column :listings, :conditions, :text
    add_column :listings, :mail,       :text
    add_column :event_natures, :active, :boolean, :null=>false, :default=>true
  end

  def self.down
    remove_column :event_natures, :active
    remove_column :listings, :mail
    remove_column :listings, :conditions
    add_column :listing_nodes, :comparator, :string
    add_column :listing_nodes, :reflection_name, :string
    remove_column :listing_nodes, :attribute_name
    remove_column :listing_nodes, :condition_operator
    remove_column :listing_nodes, :condition_value
    remove_column :listing_nodes, :sql_type
    remove_column :listing_nodes, :key
  end
end
