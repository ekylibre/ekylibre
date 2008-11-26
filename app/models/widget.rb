# == Schema Information
# Schema version: 20080819191919
#
# Table name: widgets
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  location     :string(255)   not null
#  nature       :string(255)   not null
#  options      :text          
#  position     :integer       
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Widget < ActiveRecord::Base
end
