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

  
  def before_validation_on_create
  end

end
