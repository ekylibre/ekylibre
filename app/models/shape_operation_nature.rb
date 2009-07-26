# == Schema Information
#
# Table name: shape_operation_natures
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class ShapeOperationNature < ActiveRecord::Base

  belongs_to :company
  has_many :shape_operations

end
