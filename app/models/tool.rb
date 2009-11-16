class Tool < ActiveRecord::Base

  attr_readonly :company_id
  
  def self.natures
    [:tractor, :towed, :other].collect{|x| [tc('natures.'+x.to_s), x] }
  end
  
  def text_nature
    tc('natures.'+self.nature)
  end


end
