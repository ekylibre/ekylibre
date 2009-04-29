class Meeting < ActiveRecord::Base

  belongs_to :company
  belongs_to :employee
  belongs_to :entity
  belongs_to :location, :class_name=>MeetingLocation.to_s
  belongs_to :mode, :class_name=>MeetingMode.to_s
 
  
  attr_readonly :company_id

end
