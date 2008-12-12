# == Schema Information
# Schema version: 20081127140043
#
# Table name: stock_locations
#
#  id               :integer       not null, primary key
#  name             :string(255)   not null
#  x                :string(255)   
#  y                :string(255)   
#  z                :string(255)   
#  comment          :text          
#  parent_id        :integer       not null
#  account_id       :integer       not null
#  establishment_id :integer       not null
#  contact_id       :integer       not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#

class StockLocation < ActiveRecord::Base
end
