# == Schema Information
#
# Table name: invoice_lines
#
#  id                :integer       not null, primary key
#  order_line_id     :integer       not null
#  product_id        :integer       not null
#  price_id          :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  position          :integer       
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#  invoice_id        :integer       
#  origin_id         :integer       
#

class InvoiceLine < ActiveRecord::Base

  belongs_to :company
  belongs_to :invoice
  belongs_to :origin, :class_name=>InvoiceLine.to_s
  belongs_to :price
  belongs_to :product
  belongs_to :order_line, :class_name=>SaleOrderLine.to_s
  
  def before_validation
    self.product = self.order_line.product
    self.price_id = self.order_line.price.id
    #line = InvoiceLine.find(:first, :conditions=>{:company_id=>self.company_id, :product_id=>self.order_line.product_id, :price_id=>self.price_id, :invoice_id=>self.invoice_id})
    #raise Exception.new line.inspect
    #line.update_attributes!(:quantity=>(line.quantity + self.quantity),:amount=>(line.amount + self.amount),:amount_with_taxes=>(line.amount_with_taxes + self.amount_with_taxes) ) if !line.nil? and line.id != self.id
    #self.unit_id = self.order_line.unit.id
    #rslt = line.nil? true : false 
    #false if !line.nil? and line.id != self.id
    #self.destroy if !line.nil?
    #true if line.nil?

    if !self.origin_id.nil?
      self.amount = self.quantity * self.price.amount
      self.amount_with_taxes = self.quantity * self.price.amount_with_taxes
    end
    
  end
  
  def validate
    if !self.origin_id.nil?
      errors.add(:quantity) if ((self.quantity*-1) > self.origin.quantity)
    end
  end

  def after_create
    #raise Exception.new self.inspect
    record = JournalRecord.find(:first, :conditions=>{:resource_id=>self.invoice_id, :resource_type=>Invoice.to_s, :company_id=>self.company_id})
    
    record = JournalRecord.create!(:company_id=>self.company_id, :resource_id=>self.invoice_id, :resource_type=>Invoice.to_s, :created_on=>Date.today, :printed_on=>Date.today, :financialyear_id=>self.company.financialyears.find(1), :journal_id=>self.company.find_sales_journal) if record.nil?

    Entry.create!(:company_id=>self.company_id, :record_id=>record.id, :account_id=>self.product.product_account_id, :currency_id=>self.price.currency_id,:editable=>false, :credit=>self.amount_with_taxes, :name=>self.product.name+" "+self.price.amount_with_taxes.to_s+" "+self.price.currency.code, :currency_credit=>1)
  end

  def after_save
    if !self.origin_id.nil?
      self.invoice.save 
    end
  end



  
end
