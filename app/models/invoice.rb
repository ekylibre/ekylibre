# == Schema Information
#
# Table name: invoices
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  client_id         :integer       not null
#  company_id        :integer       not null
#  contact_id        :integer       not null
#  created_at        :datetime      not null
#  created_on        :date          
#  creator_id        :integer       
#  credit            :boolean       not null
#  downpayment_price :decimal(16, 2 default(0.0), not null
#  has_downpayment   :boolean       not null
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  lost              :boolean       not null
#  nature            :string(1)     not null
#  number            :string(64)    not null
#  origin_id         :integer       
#  paid              :boolean       not null
#  payment_delay_id  :integer       not null
#  payment_on        :date          not null
#  sale_order_id     :integer       
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

class Invoice < ActiveRecord::Base

  belongs_to :client, :class_name=>Entity.to_s
  belongs_to :company
  belongs_to :contact
  belongs_to :origin, :class_name=>Invoice.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :sale_order
  has_many :deliveries
  has_many :lines, :class_name=>InvoiceLine.to_s, :foreign_key=>:invoice_id

  attr_readonly :company_id

  def before_validation
    self.created_on = Date.today unless self.created_on.is_a? Date
    if self.number.blank?
      last = self.client.invoices.find(:first, :order=>"number desc")
      self.number = if last
                      last.number.succ!
                    else
                      '00000001'
                    end
    end
    if self.credit
      self.amount = 0
      self.amount_with_taxes = 0
      for line in self.lines
        self.amount += line.amount
        self.amount_with_taxes += line.amount_with_taxes
      end
    end
    
  end
  
  def before_validation_on_create
    if self.credit and self.origin
      self.payment_on = Date.today if self.payment_on.nil?
      self.contact_id = self.origin.contact_id
      self.nature = "C"
      self.payment_delay_id = self.origin.payment_delay_id
      self.sale_order_id = self.origin.sale_order_id
    end
  end
  
  def after_validation_on_create
    specific_numeration = self.company.parameter("management.invoicing.numeration").value
    if not specific_numeration.nil?
      self.number = specific_numeration.next_value
    end
  end

  def after_create
    self.client.add_event(:invoice, self.updater_id) if self.updater
  end

  def self.generate(company_id, records)
    puts "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm"+records.class.to_s
    invoice = Invoice.new(:company_id=>company_id, :nature=>"S")
    case records.class.to_s
      
    when "Array"
      for record in records
        invoice.amount += record.amount
        invoice.amount_with_taxes += record.amount_with_taxes
      end
      invoice.sale_order_id = records[0].order_id
      invoice.payment_delay_id = records[0].order.payment_delay_id
      invoice.client_id = records[0].order.client_id
      invoice.contact_id = records[0].order.invoice_contact_id
      invoice.payment_on = Date.today
      invoice.save!
      for record in records
        record.update_attributes!(:invoice_id=>invoice.id)
        for lines in record.lines
          if lines.quantity > 0
            line = InvoiceLine.find(:first, :conditions=>{:company_id=>lines.company_id, :product_id=>lines.order_line.product_id, :price_id=>lines.price_id, :invoice_id=>invoice.id})
            if line.nil?
              invoice_line = InvoiceLine.create!(:company_id=>lines.company_id,:amount=>lines.amount,
                                                 :amount_with_taxes=>lines.amount_with_taxes,:invoice_id=>invoice.id,
                                                 :order_line_id=>lines.order_line_id,:quantity=>lines.quantity) 
              invoice_line.save!
            else
              line.update_attributes(:quantity=>(line.quantity + lines.quantity),:amount=>(line.amount + lines.amount),:amount_with_taxes=>(line.amount_with_taxes + lines.amount_with_taxes))
            end
          end
        end
      end
      
      
    when "Delivery"
      invoice.amount = records.amount
      invoice.amount_with_taxes = records.amount_with_taxes
      invoice.payment_delay_id = records.order.payment_delay_id
      invoice.client_id = records.order.client_id
      invoice.payment_on = Date.today
      invoice.sale_order_id = records.id
      invoice.contact_id = records.order.invoice_contact_id
      invoice.save!
      records.update_attributes!(:invoice_id=>invoice.id)
      for lines in records.lines
        if lines.quantity > 0
          line = InvoiceLine.create!(:company_id=>lines.company_id,:amount=>lines.amount,
                                     :amount_with_taxes=>lines.amount_with_taxes,:invoice_id=>invoice.id,
                                     :order_line_id=>lines.order_line_id,:quantity=>lines.order_line.quantity)
          line.save
        end
      end
      
    when "SaleOrder"
      invoice.amount = records.amount
      invoice.amount_with_taxes = records.amount_with_taxes
      invoice.payment_delay_id = records.payment_delay_id
      invoice.client_id = records.client_id
      invoice.payment_on = Date.today
      invoice.contact_id = records.invoice_contact_id
      invoice.sale_order_id = records.id
      invoice.save!
      puts invoice.inspect
      records.update_attributes!(:invoiced=>true)
      for lines in records.lines
        if lines.quantity > 0
          line = InvoiceLine.create!(:company_id=>lines.company_id,:amount=>lines.amount,
                                     :amount_with_taxes=>lines.amount_with_taxes,:invoice_id=>invoice.id,
                                     :order_line_id=>lines.id,:quantity=>lines.quantity)
          line.save
        end
      end
    end
    
  end
  
 def status
   status = ""
   status = "critic" if self.credit
   status
 end

 def product_name
   self.product.name
 end

end
