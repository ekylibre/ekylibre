# == Schema Information
#
# Table name: templates
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  content      :text          not null
#  cache        :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class Template < ActiveRecord::Base
  belongs_to :company
 
end
