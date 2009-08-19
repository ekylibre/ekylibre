# == Schema Information
#
# Table name: observations
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          not null
#  entity_id    :integer       not null
#  id           :integer       not null, primary key
#  importance   :string(10)    not null
#  lock_version :integer       default(0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Observation < ActiveRecord::Base
  belongs_to :company
  belongs_to :entity

  attr_readonly :company_id
  
  
  def self.importances
    [:important, :normal, :notice].collect{|x| [tc('importances.'+x.to_s), x] }
  end


  def text_importance
    tc('importances.'+self.importance.to_s)
  end

  def status
    status = ""
    case self.importance
    when "important"
      status = "critic"
    when "normal"
      status = "minimum"
    end
    status
  end
  
end
