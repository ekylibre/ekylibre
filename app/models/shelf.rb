# == Schema Information
#
# Table name: shelves
#
#  catalog_description :text          
#  catalog_name        :string(255)   not null
#  comment             :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  creator_id          :integer       
#  id                  :integer       not null, primary key
#  lock_version        :integer       default(0), not null
#  name                :string(255)   not null
#  parent_id           :integer       
#  updated_at          :datetime      not null
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
