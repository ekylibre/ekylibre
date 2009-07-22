# == Schema Information
#
# Table name: listing_nodes
#
#  id                   :integer       not null, primary key
#  name                 :string(255)   not null
#  label                :string(255)   not null
#  nature               :string(255)   not null
#  reflection_name      :string(255)   
#  position             :integer       
#  exportable           :boolean       default(TRUE), not null
#  parent_id            :integer       
#  comparator           :string(16)    
#  item_nature          :string(8)     
#  item_value           :text          
#  item_listing_id      :integer       
#  item_listing_node_id :integer       
#  listing_id           :integer       not null
#  company_id           :integer       not null
#  created_at           :datetime      not null
#  updated_at           :datetime      not null
#  creator_id           :integer       
#  updater_id           :integer       
#  lock_version         :integer       default(0), not null
#

class ListingNode < ActiveRecord::Base
  belongs_to :company
  belongs_to :listing
  belongs_to :item_listing, :class_name=>Listing.name
  belongs_to :item_listing_node, :class_name=>ListingNode.name
  has_many :items, :class_name=>ListingNodeItem.name
  acts_as_list :scope=>:listing_id
  acts_as_tree
  attr_readonly :company_id, :listing_id, :nature
  
end
