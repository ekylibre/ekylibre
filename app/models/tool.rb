# == Schema Information
#
# Table name: tools
#
#  company_id   :integer       not null
#  consumption  :decimal(, )   
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nature       :string(8)     not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Tool < ActiveRecord::Base

  belongs_to :company
  has_many :uses, :class_name=>ToolUse.name

  attr_readonly :company_id
  
  def self.natures
    [:tractor, :towed, :other].collect{|x| [tc('natures.'+x.to_s), x] }
  end
  
  def text_nature
    tc('natures.'+self.nature)
  end

  def usage_duration_sum
    sum = 0
    self.uses.each do |usage|
      sum += usage.shape_operation.duration
    end
    sum/60
  end

end
