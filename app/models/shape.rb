# == Schema Information
# Schema version: 20090520140946
#
# Table name: shapes
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  polygon      :string(255)   not null
#  master       :boolean       default(TRUE), not null
#  description  :text          
#  parent_id    :integer       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Shape < ActiveRecord::Base

  belongs_to :company
  has_many :shape_operations
  has_many :shapes

  acts_as_tree

end
