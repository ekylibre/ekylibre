# == Schema Information
#
# Table name: professions
#
#  code         :string(255)   
#  commercial   :boolean       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  rome         :string(255)   
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Profession < ActiveRecord::Base
  belongs_to :company
  has_many :employees
end
