# == Schema Information
# Schema version: 20081111111111
#
# Table name: menus
#
#  id           :integer       not null, primary key
#  name         :string(32)    not null
#  label        :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Menu < ActiveRecord::Base

  has_many :menu_items

end 
