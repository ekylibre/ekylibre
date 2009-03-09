# == Schema Information
# Schema version: 20090223113550
#
# Table name: invoices
#
#  id                :integer       not null, primary key
#  client_id         :integer       not null
#  nature            :string(1)     not null
#  number            :string(64)    not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  payment_delay_id  :integer       not null
#  payment_on        :date          not null
#  paid              :boolean       not null
#  lost              :boolean       not null
#  has_downpayment   :boolean       not null
#  downpayment_price :decimal(16, 2 default(0.0), not null
#  contact_id        :integer       not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class Invoice < ActiveRecord::Base

  def before_validation
    if self.number.blank?
      last = self.client.sale_orders.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end
  end
  
  def self.generate(company, records) 
    invoice = Invoice.new(:company_id=>company.id)
    case records.class
      
    when "Array"
      
    when  Delivery
      invoice.amount = records.amount
      invoice.amount_with_taxes = records.amount_with_taxes
      invoice.payment_delay_id = records.order.payment_delay_id
      invoice.client_id = records.order.client_id
      invoice.payment_on = Date.today
      invoice.contact_id = records.order.invoice_contact_id
      invoice.save
      
      for lines in records.lines
        line = invoice.line.create!(:company_id=>lines.company_id,:amount=>lines.amount,
                                    :amount_with_taxes=>lines.amount_with_taxes,
                                    :order_line_id=>lines.order_line_id,:quantity=>lines.order_line.quantity)
        line.save
      end
      
    when "SaleOrderLine"
      
    end
  
  end
  


end
