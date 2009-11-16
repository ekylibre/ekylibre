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


end
