# == Schema Information
#
# Table name: shelves
#
#  id                  :integer       not null, primary key
#  name                :string(255)   not null
#  catalog_name        :string(255)   not null
#  catalog_description :text          
#  comment             :text          
#  parent_id           :integer       
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  lock_version        :integer       default(0), not null
#  creator_id          :integer       
#  updater_id          :integer       
#

class Shelf < ActiveRecord::Base

  belongs_to :company
  has_many :products
  has_many :shelves

  acts_as_tree

  def before_validation
    self.catalog_name = self.name if self.catalog_name.blank?
  end

  def to_s
    self.name
  end

  def depth
    if self.parent.nil?
      0
    else
      self.parent.depth+1
    end
  end

end
