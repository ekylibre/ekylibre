# == Schema Information
# Schema version: 20081127140043
#
# Table name: sale_order_lines
#
#  id               :integer       not null, primary key
#  order_id         :integer       not null
#  product_id       :integer       not null
#  price_list_id    :integer       not null
#  price_id         :integer       not null
#  invoiced         :boolean       not null
#  quantity         :decimal(16, 2 default(1.0), not null
#  unit_id          :integer       not null
#  price            :decimal(16, 2 default(0.0), not null
#  price_with_taxes :decimal(16, 2 default(0.0), not null
#  position         :integer       
#  account_id       :integer       not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#

class SaleOrderLine < ActiveRecord::Base
end
