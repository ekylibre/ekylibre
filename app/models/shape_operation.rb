class ShapeOperation < ActiveRecord::Base

  belongs_to :company
  belongs_to :shape
  belongs_to :employee
  belongs_to :nature, :class_name=>ShapeOperationNature.to_s
 
  def before_validation_on_create
    self.started_at = Time.now if self.started_at.nil?
  end

end
