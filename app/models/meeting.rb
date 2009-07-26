# == Schema Information
#
# Table name: meetings
#
#  address        :text          
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  creator_id     :integer       
#  description    :text          
#  employee_id    :integer       not null
#  entity_id      :integer       not null
#  id             :integer       not null, primary key
#  location_id    :integer       not null
#  lock_version   :integer       default(0), not null
#  mode_id        :integer       not null
#  taken_place_on :date          not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
#

class Meeting < ActiveRecord::Base

  belongs_to :company
  belongs_to :employee
  belongs_to :entity
  belongs_to :location, :class_name=>MeetingLocation.to_s
  belongs_to :mode, :class_name=>MeetingMode.to_s
 
  
  attr_readonly :company_id

end
