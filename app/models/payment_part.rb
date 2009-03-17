# == Schema Information
# Schema version: 20090311124450
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
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class PaymentPart < ActiveRecord::Base
  

  def validate
    errors.add_to_base tc(:error_sale_order_already_paid) if self.amount <= 0
  end

 def payment_way
   self.payment.mode.name
  end

end
