# == Schema Information
#
# Table name: tool_uses
#
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  id                 :integer       not null, primary key
#  lock_version       :integer       default(0), not null
#  shape_operation_id :integer       not null
#  tool_id            :integer       not null
#  updated_at         :datetime      not null
#  updater_id         :integer       
#

class ToolUse < ActiveRecord::Base

  belongs_to :company
  belongs_to :shape_operation
  belongs_to :tool

end
