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

  def before_validation
    self.listing_id = self.parent.listing_id if self.parent
    self.company_id = self.listing.company_id if self.listing
  end

  def reflection?
    ["belongs_to", "has_many", "root"].include? self.nature.to_s
  end

  def root?
    self.parent_id.nil?
  end

  def key
    "ln#{self.id}"
  end

  def model
    if self.root?
      self.listing.root_model
    else
      self.parent.model.reflections[self.reflection_name.to_sym].class_name
    end.classify.constantize
  end

  def available_nodes
    nodes = []
    return nodes unless self.reflection?
    model = self.model
    # Columns
    nodes += model.content_columns.collect{|x| "column-"+x.name}.sort
    # Reflections
    nodes += model.reflections.select{|k,v| [:has_many, :belongs_to].include? v.macro}.collect{|a,b| b.macro.to_s+"-"+a.to_s}
    return nodes.sort
  end
  
end
