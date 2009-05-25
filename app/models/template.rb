# == Schema Information
# Schema version: 20090512102847
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
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Template < ActiveRecord::Base
  belongs_to :company
 
end
