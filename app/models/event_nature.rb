# == Schema Information
#
# Table name: event_natures
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  duration     :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class EventNature < ActiveRecord::Base
  
  belongs_to :company
  has_many :events

  attr_readonly :company_id, :name

  
  def self.usages
    [:manual, :sale_order, :purchase_order, :invoice].collect{|x| [tc('usages.'+x.to_s), x] }
  end
  
  def text_usage
    self.usage.blank? ? "" :   tc('usages.'+self.usage.to_s)
  end

end
