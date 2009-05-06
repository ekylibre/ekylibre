# == Schema Information
# Schema version: 20090428134248
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
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class Meeting < ActiveRecord::Base

  belongs_to :company
  belongs_to :employee
  belongs_to :entity
  belongs_to :location, :class_name=>MeetingLocation.to_s
  belongs_to :mode, :class_name=>MeetingMode.to_s
 
  
  attr_readonly :company_id

end
