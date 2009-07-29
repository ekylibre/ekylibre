# == Schema Information
#
# Table name: events
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  duration     :integer       
#  employee_id  :integer       not null
#  entity_id    :integer       not null
#  id           :integer       not null, primary key
#  location     :string(255)   
#  lock_version :integer       default(0), not null
#  nature_id    :integer       not null
#  reason       :text          
#  started_at   :datetime      not null
#  started_sec  :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Event < ActiveRecord::Base

  belongs_to :company
  belongs_to :employee
  belongs_to :entity
  belongs_to :nature, :class_name=>EventNature.to_s
    
  attr_readonly :company_id

  def before_validation
    self.started_sec = self.started_at.to_i
  end

end
