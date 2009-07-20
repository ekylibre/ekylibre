# == Schema Information
#
# Table name: departments
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  comment      :text          
#  parent_id    :integer       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class Department < ActiveRecord::Base
end
