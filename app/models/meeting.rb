# == Schema Information
#
# Table name: meetings
#
#  id             :integer       not null, primary key
#  entity_id      :integer       not null
#  location_id    :integer       not null
#  employee_id    :integer       not null
#  mode_id        :integer       not null
#  taken_place_on :date          not null
#  address        :text          
#  description    :text          
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  lock_version   :integer       default(0), not null
#  creator_id     :integer       
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
