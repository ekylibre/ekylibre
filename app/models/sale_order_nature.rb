# == Schema Information
# Schema version: 20090407073247
#
# Table name: sale_order_natures
#
#  id                  :integer       not null, primary key
#  name                :string(255)   not null
#  expiration_id       :integer       not null
#  active              :boolean       default(TRUE), not null
#  payment_delay_id    :integer       not null
#  downpayment         :boolean       not null
#  downpayment_minimum :decimal(16, 2 default(0.0), not null
#  downpayment_rate    :decimal(16, 2 default(0.0), not null
#  comment             :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#

class SaleOrderNature < ActiveRecord::Base

  belongs_to :company
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :expiration, :class_name=>Delay.to_s
  has_many :sale_orders

end
