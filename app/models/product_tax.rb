# == Schema Information
# Schema version: 20081111111111
#
# Table name: product_taxes
#
#  id           :integer       not null, primary key
#  product_id   :integer       not null
#  tax_id       :integer       not null
#  amount       :decimal(16, 4 default(0.0), not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class ProductTax < ActiveRecord::Base
end
