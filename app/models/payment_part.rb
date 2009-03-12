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
  
  def before_validation
    self.amount = self.payment.amount


#     amount = PaymentPart.sum(:amount, :conditions=>{:order_id=>self.order_id,:company_id=>self.company_id})
#     sale_order = find_and_check(:sale_order, self.order_id)
#     if surplus = (amount - sale_order.amount_with_taxes ) > 0
#       payment_part = PaymentPart.new(:amount=>surplus,:order_id=>self.order_id,:company_id=>self.company_id,:payment_id=>a)
#     end
  end



end
