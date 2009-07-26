# == Schema Information
#
# Table name: listing_nodes
#
#  company_id           :integer       not null
#  comparator           :string(16)    
#  created_at           :datetime      not null
#  creator_id           :integer       
#  exportable           :boolean       default(TRUE), not null
#  id                   :integer       not null, primary key
#  item_listing_id      :integer       
#  item_listing_node_id :integer       
#  item_nature          :string(8)     
#  item_value           :text          
#  label                :string(255)   not null
#  listing_id           :integer       not null
#  lock_version         :integer       default(0), not null
#  name                 :string(255)   not null
#  nature               :string(255)   not null
#  parent_id            :integer       
#  position             :integer       
#  reflection_name      :string(255)   
#  updated_at           :datetime      not null
#  updater_id           :integer       
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
  @@natures = [:datetime, :boolean, :string, :numeric, :belongs_to, :has_many]
  
  def self.natures
    hash = {}
    @@natures.each{|n| hash[n] = tc('natures.'+n.to_s) }
    hash
  end

  

  
end
