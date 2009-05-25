# == Schema Information
# Schema version: 20090512102847
#
# Table name: shape_operations
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  description  :text          
#  shape_id     :integer       not null
#  employee_id  :integer       not null
#  nature_id    :integer       
#  planned_on   :date          not null
#  moved_on     :date          
#  started_at   :datetime      not null
#  stopped_at   :datetime      
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class ShapeOperation < ActiveRecord::Base

  belongs_to :company
  belongs_to :shape
  belongs_to :employee
  belongs_to :nature, :class_name=>ShapeOperationNature.to_s
 
  def before_validation_on_create
    self.started_at = Time.now if self.started_at.nil?
  end

end
