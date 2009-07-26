# == Schema Information
#
# Table name: meeting_locations
#
#  active       :boolean       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class MeetingLocation < ActiveRecord::Base

  belongs_to :company
  has_many :meetings
  has_many :entities

  attr_readonly :company_id, :name, :description

  def before_validation_on_create
    self.active = true
  end

  def before_update
    MeetingLocation.create!(self.attributes.merge({:active=>true, :company_id=>self.company_id})) if self.active
    self.active = false
    true
  end

end
