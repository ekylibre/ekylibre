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
#  tools_list    :string(255)   
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

class ShapeOperation < ActiveRecord::Base
  belongs_to :company
  belongs_to :shape
  belongs_to :employee
  belongs_to :nature, :class_name=>ShapeOperationNature.name
  has_many :tool_uses
  has_many :tools, :through=>:tool_uses

  attr_readonly :company_id
 
  def before_validation_on_create
    self.started_at = Time.now if self.started_at.nil?
  end

  def before_validation
    self.duration = (self.min_duration.to_i + (self.hour_duration.to_i)*60 )
  end

  def before_destroy
    self.tool_uses.destroy_all if self.tool_uses
  end

  def add_tools(tools)
    self.tool_uses.destroy_all if self.tool_uses
    unless tools.nil?
      tools.each do |tool|
        self.company.tool_uses.create!(:shape_operation_id=>self.id, :tool_id=>tool[0].to_i)
      end
    end
    self.reload
    self.tools_list = self.tools.collect{|t| t.name}.join(", ")
    self.save
  end

end
