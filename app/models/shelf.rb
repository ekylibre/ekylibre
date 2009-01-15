# == Schema Information
# Schema version: 20081127140043
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
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#

class Shelf < ActiveRecord::Base

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
