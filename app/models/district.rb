# == Schema Information
#
# Table name: districts
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class District < ActiveRecord::Base
  belongs_to :company
  has_many :cities
  
  attr_readonly :company_id
end
