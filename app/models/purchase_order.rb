# == Schema Information
# Schema version: 20090223113550
#
# Table name: purchase_orders
#
#  id                :integer       not null, primary key
#  supplier_id       :integer       not null
#  number            :string(64)    not null
#  shipped           :boolean       not null
#  invoiced          :boolean       not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  dest_contact_id   :integer       
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class PurchaseOrder < ActiveRecord::Base
  
  def before_validation
    #raise Exception.new self.inspect
    if self.number.blank?
      last = self.supplier.purchase_orders.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end


    self.amount = 0
    self.amount_with_taxes = 0
     for line in self.lines
       self.amount += line.amount
       self.amount_with_taxes += line.amount_with_taxes
       #raise Exception.new self.inspect
     end
  end
  
  def up_order
    self.save
  end

  
#   def deleted_line(id)
#     for line in self.lines
#       puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!       "+line.inspect
#       self.amount += line.amount unless line.id==id
#       self.amount_with_taxes += line.amount_with_taxes unless line.id==id
#       #raise Exception.new self.inspect
#     end 
  #     self.save
#   end
  
end
