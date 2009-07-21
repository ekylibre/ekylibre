class SubscriptionNature < ActiveRecord::Base

  belongs_to :company
  has_many :products

 def self.natures
   [:quantity, :period].collect{|x| [tc('natures.'+x.to_s), x] }
  end

end
