# == Schema Information
#
# Table name: listing_node_items
#
#  id           :integer       not null, primary key
#  node_id      :integer       not null
#  nature       :string(8)     not null
#  value        :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  creator_id   :integer       
#  updater_id   :integer       
#  lock_version :integer       default(0), not null
#

class ListingNodeItem < ActiveRecord::Base
  belongs_to :company
  belongs_to :node, :class_name=>ListingNode.name
  attr_readonly :company_id, :node_id

end
