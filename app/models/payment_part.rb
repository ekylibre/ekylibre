# == Schema Information
#
# Table name: payment_parts
#
#  amount       :decimal(16, 2 
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  order_id     :integer       not null
#  payment_id   :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class PaymentPart < ActiveRecord::Base
  
  belongs_to :company
  belongs_to :payment
  belongs_to :order, :class_name=>SaleOrder.to_s

  def validate
    errors.add_to_base tc(:error_sale_order_already_paid) if self.amount <= 0 and self.payment.downpayment == false
  end

  def payment_way
    self.payment.mode.name
  end
  
  def real?
    not self.payment.scheduled or (self.payment.scheduled and self.payment.validated)
  end
 

end
