class ShapeOperationNature < ActiveRecord::Base

  belongs_to :company
  has_many :shape_operations

end
