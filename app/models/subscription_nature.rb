# == Schema Information
#
# Table name: subscription_natures
#
#  actual_number         :integer       
#  comment               :text          
#  company_id            :integer       not null
#  created_at            :datetime      not null
#  creator_id            :integer       
#  entity_link_nature_id :integer       
#  id                    :integer       not null, primary key
#  lock_version          :integer       default(0), not null
#  name                  :string(255)   not null
#  nature                :string(8)     not null
#  reduction_rate        :decimal(8, 2) 
#  updated_at            :datetime      not null
#  updater_id            :integer       
#

class SubscriptionNature < ActiveRecord::Base
  belongs_to :company
  belongs_to :entity_link_nature
  has_many :products

  validates_numericality_of :reduction_rate, :greater_than=>0, :less_than_or_equal_to=>1

  def self.natures
    [:quantity, :period].collect{|x| [tc('natures.'+x.to_s), x] }
  end


  def nature_label
    tc('natures.'+self.nature.to_s)
  end

  def period?
    self.nature == "period"
  end

  def now
    return (self.period? ? Date.today : self.actual_number)
  end


end

