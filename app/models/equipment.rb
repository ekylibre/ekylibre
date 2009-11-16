# == Schema Information
#
# Table name: equipment
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

class Equipment < ActiveRecord::Base

 attr_readonly :company_id

  def self.natures
    [:tractor, :towed, :other].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def text_nature
    tc('natures.'+self.nature)
  end

end
