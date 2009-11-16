class ToolUse < ActiveRecord::Base

  belongs_to :company
  belongs_to :shape_operation
  belongs_to :tool

end
