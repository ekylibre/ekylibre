# == Schema Information
#
# Table name: payment_parts
#
#  id           :integer       not null, primary key
#  amount       :decimal(16, 2 
#  payment_id   :integer       not null
#  order_id     :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class PaymentPart < ActiveRecord::Base
  
  belongs_to :company
  belongs_to :payment
  belongs_to :order, :class_name=>SaleOrder.to_s

  def validate
    errors.add_to_base tc(:error_sale_order_already_paid) if self.amount <= 0
  end

 def payment_way
   self.payment.mode.name
  end

end
