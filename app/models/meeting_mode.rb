# == Schema Information
# Schema version: 20090428134248
#
# Table name: meeting_modes
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  active       :boolean       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class MeetingMode < ActiveRecord::Base
  
  belongs_to :company
  has_many :meetings

  attr_readonly :company_id, :name

  
  def before_validation_on_create
    self.active = true
  end

  def before_update
    MeetingMode.create!(self.attributes.merge({:active=>true, :company_id=>self.company_id})) if self.active
    self.active = false
    true
  end

end
