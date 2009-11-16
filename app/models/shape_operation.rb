# == Schema Information
#
# Table name: shape_operations
#
#  company_id    :integer       not null
#  consumption   :decimal(, )   
#  created_at    :datetime      not null
#  creator_id    :integer       
#  description   :text          
#  duration      :decimal(, )   
#  employee_id   :integer       not null
#  hour_duration :decimal(, )   
#  id            :integer       not null, primary key
#  lock_version  :integer       default(0), not null
#  min_duration  :decimal(, )   
#  moved_on      :date          
#  name          :string(255)   not null
#  nature_id     :integer       
#  planned_on    :date          not null
#  shape_id      :integer       not null
#  started_at    :datetime      not null
#  stopped_at    :datetime      
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

class ShapeOperation < ActiveRecord::Base
  belongs_to :company
  belongs_to :shape
  belongs_to :employee
  belongs_to :nature, :class_name=>ShapeOperationNature.to_s
  has_and_belongs_to_many :shape_operations_tools

  attr_readonly :company_id
 
  def before_validation_on_create
    self.started_at = Time.now if self.started_at.nil?
  end

  def add_tools(tools)
    unless tools.nil?
      tools.each do |tool|
        self.company.shape_operations_tools.create!(:shape_operation_id=>self.id, :tool_id=>tool[0].to_i)
        #raise Exception.new tool.inspect
      end
    end
  end


end
