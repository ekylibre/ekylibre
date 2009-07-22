# == Schema Information
#
# Table name: subscription_natures
#
#  id            :integer       not null, primary key
#  name          :string(255)   not null
#  actual_number :integer       
#  nature        :string(8)     not null
#  comment       :text          
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  creator_id    :integer       
#  updater_id    :integer       
#  lock_version  :integer       default(0), not null
#

class SubscriptionNature < ActiveRecord::Base

  belongs_to :company
  has_many :products

 def self.natures
   [:quantity, :period].collect{|x| [tc('natures.'+x.to_s), x] }
  end

 def read_nature
   tc('natures.'+self.nature.to_s)
 end

end
