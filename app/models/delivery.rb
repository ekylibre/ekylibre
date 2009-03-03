# == Schema Information
# Schema version: 20081111111111
#
# Table name: deliveries
#
#  id                :integer       not null, primary key
#  order_id          :integer       not null
#  invoice_id        :integer       
#  shipped_on        :date          not null
#  delivered_on      :date          not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class Delivery < ActiveRecord::Base

  def before_validation
    self.amount = 0
    self.amount_with_taxes = 0
    for line in self.lines
      self.amount += line.amount
      self.amount_with_taxes += line.amount_with_taxes
    end
  end
  
end
