# == Schema Information
#
# Table name: invoice_lines
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  annotation        :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  entity_id         :integer       
#  id                :integer       not null, primary key
#  invoice_id        :integer       
#  lock_version      :integer       default(0), not null
#  order_line_id     :integer       
#  origin_id         :integer       
#  position          :integer       
#  price_id          :integer       not null
#  product_id        :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

class InvoiceLine < ActiveRecord::Base
  belongs_to :company
  belongs_to :entity
  belongs_to :invoice
  belongs_to :order_line, :class_name=>SaleOrderLine.name
  belongs_to :origin, :class_name=>InvoiceLine.name
  belongs_to :price
  belongs_to :product
  has_many :credit_lines, :class_name=>InvoiceLine.name, :foreign_key=>:origin_id

  validates_presence_of :order_line_id

  attr_readonly :company_id, :invoice_id, :order_line_id, :quantity, :amount, :amount_with_taxes, :annotation, :price_id, :product_id
  
  def before_validation
    self.product = self.order_line.product
    self.price_id = self.order_line.price.id
    self.annotation = self.order_line.annotation
    #line = InvoiceLine.find(:first, :conditions=>{:company_id=>self.company_id, :product_id=>self.order_line.product_id, :price_id=>self.price_id, :invoice_id=>self.invoice_id})
    #raise Exception.new line.inspect
    #line.update_attributes!(:quantity=>(line.quantity + self.quantity),:amount=>(line.amount + self.amount),:amount_with_taxes=>(line.amount_with_taxes + self.amount_with_taxes) ) if !line.nil? and line.id != self.id
    #self.unit_id = self.order_line.unit.id
    #rslt = line.nil? true : false 
    #false if !line.nil? and line.id != self.id
    #self.destroy if !line.nil?
    #true if line.nil?

    unless self.origin_id.nil?
      self.amount = self.quantity * self.price.amount
      self.amount_with_taxes = self.quantity * self.price.amount_with_taxes
    end
    
  end
  
  def validate
    unless self.origin_id.nil?
      if self.origin.quantity > 0
        errors.add(:quantity) if -self.quantity > self.origin.quantity
      else
        errors.add(:quantity) if -self.quantity < self.origin.quantity
      end
    end
  end

  def after_create

#     if self.amount > 0 ## avoirs non traités
#       record = JournalRecord.find(:first, :conditions=>{:resource_id=>self.invoice_id, :resource_type=>Invoice.to_s, :company_id=>self.company_id})
      
#       #raise Exception.new self.company.parameter("accountancy.default_journals.sales").inspect

#       record = JournalRecord.create!(:company_id=>self.company_id, :resource_id=>self.invoice_id, :resource_type=>Invoice.to_s, :created_on=>Date.today, :printed_on=>Date.today, :financialyear_id=>self.company.financialyears.find_by_closed(false), :journal_id=>self.company.parameter("accountancy.default_journals.sales").value.id) if record.nil?

#        ### Product Account (credit, 7...)
#       Entry.create!(:company_id=>self.company_id, :record_id=>record.id, :account_id=>self.product.product_account_id, :currency_id=>self.price.currency_id,:editable=>false, :credit=>self.amount, :name=>self.product.name+" "+self.price.amount.to_s+" "+self.price.currency.code, :currency_credit=>1)

#       ### Tax amount (credit, 445..)
#       Entry.create!(:company_id=>self.company_id, :record_id=>record.id, :account_id=>self.price.tax.account_collected_id, :currency_id=>self.price.currency_id,:editable=>false, :credit=>(self.amount_with_taxes - self.amount), :name=>self.price.tax.name+" "+(self.amount_with_taxes - self.amount).to_s+" "+self.price.currency.code, :currency_credit=>1)

#       ### Charge account,  client (debit, 411..)
#       Entry.create!(:company_id=>self.company_id, :record_id=>record.id, :account_id=>self.order_line.order.client.find_or_create_account, :currency_id=>self.price.currency_id, :editable=>false, :debit=>self.amount_with_taxes, :name=>self.product.name+" "+self.price.amount_with_taxes.to_s+" "+self.price.currency.code, :currency_credit=>1)
#     end
    
  end

  def after_save
    self.invoice.save unless self.origin_id.nil?
  end

  def product_name
    self.product ? self.product.name : tc(:no_product) 
  end

  def taxes
    self.amount_with_taxes - self.amount
  end  
  
  def designation
    d  = self.order_line.label
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d
  end


  
  def credited_quantity
    self.credit_lines.sum(:quantity)
  end

  def uncredited_quantity
    self.quantity - self.credited_quantity
  end

end
