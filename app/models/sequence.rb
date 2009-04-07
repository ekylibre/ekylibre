# == Schema Information
# Schema version: 20090407073247
#
# Table name: sequences
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  increment    :integer       default(1), not null
#  format       :string(255)   not null
#  active       :boolean       not null
#  next_number  :integer       default(0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Sequence < ActiveRecord::Base
end
