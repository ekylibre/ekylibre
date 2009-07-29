# == Schema Information
#
# Table name: mandates
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  entity_id    :integer       not null
#  family       :string(255)   not null
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  organization :string(255)   not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  title        :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Mandate < ActiveRecord::Base
  belongs_to :entity
  belongs_to :company
  attr_readonly :company_id

  # def before_validation_on_create
#     self.started_on = Date.today
#     self.stopped_on = self.started_on
#   end
  
  
end
