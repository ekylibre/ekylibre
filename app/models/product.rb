# == Schema Information
# Schema version: 20081127140043
#
# Table name: products
#
#  id                  :integer       not null, primary key
#  to_purchase         :boolean       not null
#  to_sale             :boolean       not null
#  to_rent             :boolean       not null
#  name                :string(255)   not null
#  number              :integer       not null
#  active              :boolean       default(TRUE), not null
#  code                :string(64)    not null
#  code2               :string(64)    not null
#  ean13               :string(13)    
#  catalog_name        :string(255)   not null
#  catalog_description :text          
#  description         :text          
#  comment             :text          
#  shelf_id            :integer       not null
#  unit_id             :integer       not null
#  account_id          :integer       not null
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#

class Product < ActiveRecord::Base
end
