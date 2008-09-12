# == Schema Information
# Schema version: 20080819191919
#
# Table name: delays
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  active       :boolean       not null
#  expression   :string(255)   default("0"), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Delay < ActiveRecord::Base
end
