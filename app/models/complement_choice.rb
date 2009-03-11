# == Schema Information
# Schema version: 20090311124450
#
# Table name: complement_choices
#
#  id            :integer       not null, primary key
#  complement_id :integer       not null
#  name          :string(255)   not null
#  value         :string(255)   not null
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#

class ComplementChoice < ActiveRecord::Base
  def to_s
    self.name
  end

end
