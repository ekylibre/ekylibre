# == Schema Information
# Schema version: 20081127140043
#
# Table name: units
#
#  id           :integer       not null, primary key
#  name         :string(8)     not null
#  label        :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Unit < ActiveRecord::Base
end
