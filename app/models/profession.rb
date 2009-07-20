# == Schema Information
#
# Table name: professions
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  code         :string(255)   
#  rome         :string(255)   
#  commercial   :boolean       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class Profession < ActiveRecord::Base
  belongs_to :company
  has_many :employees
end
