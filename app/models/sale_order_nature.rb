# == Schema Information
#
# Table name: sale_order_natures
#
#  active              :boolean       default(TRUE), not null
#  comment             :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  creator_id          :integer       
#  downpayment         :boolean       not null
#  downpayment_minimum :decimal(16, 2 default(0.0), not null
#  downpayment_rate    :decimal(16, 2 default(0.0), not null
#  expiration_id       :integer       not null
#  id                  :integer       not null, primary key
#  lock_version        :integer       default(0), not null
#  name                :string(255)   not null
#  payment_delay_id    :integer       not null
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

class SaleOrderNature < ActiveRecord::Base

  belongs_to :company
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :expiration, :class_name=>Delay.to_s
  has_many :sale_orders

end
