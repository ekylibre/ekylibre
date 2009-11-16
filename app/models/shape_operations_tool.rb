class ShapeOperationsTool < ActiveRecord::Base
  belongs_to :company
  belongs_to :shape_operation
  belongs_to :tool

  attr_readonly :company_id


end
