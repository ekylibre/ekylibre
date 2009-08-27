# == Schema Information
#
# Table name: sale_orders
#
#  amount              :decimal(16, 2 default(0.0), not null
#  amount_with_taxes   :decimal(16, 2 default(0.0), not null
#  annotation          :text          
#  client_id           :integer       not null
#  comment             :text          
#  company_id          :integer       not null
#  conclusion          :text          
#  confirmed_on        :date          
#  contact_id          :integer       
#  created_at          :datetime      not null
#  created_on          :date          not null
#  creator_id          :integer       
#  delivery_contact_id :integer       
#  downpayment_amount  :decimal(16, 2 default(0.0), not null
#  expiration_id       :integer       not null
#  expired_on          :date          not null
#  function_title      :string(255)   
#  has_downpayment     :boolean       not null
#  id                  :integer       not null, primary key
#  introduction        :text          
#  invoice_contact_id  :integer       
#  invoiced            :boolean       not null
#  letter_format       :boolean       default(TRUE), not null
#  lock_version        :integer       default(0), not null
#  nature_id           :integer       not null
#  number              :string(64)    not null
#  parts_amount        :decimal(16, 2 
#  payment_delay_id    :integer       not null
#  responsible_id      :integer       
#  state               :string(1)     default("O"), not null
#  subject             :string(255)   
#  sum_method          :string(8)     default("wt"), not null
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

class SaleOrder < ActiveRecord::Base
  
  attr_readonly :company_id, :created_on, :number

  belongs_to :company
  belongs_to :invoice_contact, :class_name=>Contact.to_s
  belongs_to :delivery_contact,:class_name=>Contact.to_s
  belongs_to :contact
  belongs_to :expiration, :class_name=>Delay.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :client, :class_name=>Entity.to_s
  belongs_to :nature, :class_name=>SaleOrderNature.to_s
  belongs_to :responsible, :class_name=>Employee.to_s
  has_many :deliveries, :foreign_key=>:order_id
  has_many :invoices
  has_many :payment_parts, :foreign_key=>:order_id
  has_many :lines, :class_name=>SaleOrderLine.to_s, :foreign_key=>:order_id

  @@natures = [:estimate, :order, :invoice]
  
  def before_validation
    self.parts_amount = self.payment_parts.sum(:amount)||0
    if self.number.blank?
      last = self.company.sale_orders.find(:first, :order=>"number desc")
      self.number = last ? last.number.succ! : '00000001'
    end
    self.created_on ||= Date.today
    if self.nature
      self.expiration_id ||= self.nature.expiration_id 
      self.expired_on ||= self.expiration.compute(self.created_on)
      self.payment_delay_id ||= self.nature.payment_delay_id 
      if self.has_downpayment.nil?
        self.has_downpayment = self.nature.downpayment
      end
      self.downpayment_amount ||= self.amount_with_taxes*self.nature.downpayment_rate if self.amount_with_taxes>=self.nature.downpayment_minimum
    end

    if 1 # wt
      self.amount = 0
      self.amount_with_taxes = 0
      for line in self.lines
        self.amount += line.amount
        self.amount_with_taxes += line.amount_with_taxes
      end
    else
      
    end

  end

  def before_validation_on_create
    self.created_on = Date.today
  end

  def after_validation_on_create
    specific_numeration = self.company.parameter("management.sale_orders.numeration").value
    if not specific_numeration.nil?
      self.number = specific_numeration.next_value
    end
  end
  
  def after_create
    self.client.add_event(:sale_order, self.updater_id)
    true
  end

  def refresh
    self.save
  end


  def stats(options={})
    invoiced = self.invoices.sum(:amount_with_taxes)
    array = []
    array << [:client_balance, self.client.balance.to_s] if options[:with_balance]
    array << [:total_amount, self.amount_with_taxes]
    array << [:uninvoiced_amount, self.amount_with_taxes - invoiced]
    array << [:invoiced_amount, invoiced]
    array << [:paid_amount, paid = self.payment_parts.sum(:amount)]
    array << [:unpaid_amount, invoiced - paid]
    array
  end


  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def text_state
    tc('states.'+self.state.to_s)
  end

  def stocks_moves_create
    for line in self.lines
      StockMove.create!(:name=>tc(:sale)+"  "+self.number, :quantity=>line.quantity, :location_id=>line.location_id, :product_id=>line.product_id, :planned_on=>self.created_on, :company_id=>line.company_id, :virtual=>true, :input=>false, :origin_type=>SaleOrder.to_s, :origin_id=>self.id, :generated=>true)
    end
  end

  def undelivered(column)
    sum = 0
    if column == "amount"
      for line in self.lines
        sum += line.price.amount*line.undelivered_quantity
      end
    elsif column == "amount_with_taxes"
       for line in self.lines
        sum += line.price.amount_with_taxes*line.undelivered_quantity
       end
    end
    sum
  end

  def unpaid_amount(only_invoices=true, only_received_payments=false)
    (only_invoices ? self.invoices.sum(:amount_with_taxes) : self.amount_with_taxes).to_f - (only_received_payments ? self.payment_parts.sum(:amount, :conditions=>{:received=>true}) : self.payment_parts.sum(:amount)).to_f
  end

  def payments
    sale_orders = self.client.sale_orders
    payment_parts = [] 
    for sale_order in sale_orders
      payment_parts += sale_order.payment_parts
    end
    payments = []
    for part in payment_parts
      found = false
      pay = self.company.payments.find(:all, :conditions=>["id = ? AND amount != part_amount", part.payment_id])
      if !pay.empty? 
        for payment in payments
          found = true if payment.id == pay[0].id 
        end
        payments += pay if (!pay.nil? and !found)
        puts payments.inspect
      end
    end
    payments
  end

  def status
    status = ""
    status = "critic" if not ['F','P'].include? self.state and self.parts_amount.to_f < self.amount_with_taxes.to_f
    status
  end

  def letter?
    self.letter_format and self.state == "P" 
  end

  def need_check?
    self.letter? and self.nature.payment_type == "check"
  end

  def address
    self.contact ? self.contact.address : self.client.default_contact.address
  end

  def number_label
    tc("number_label.#{self.state=='P' ? 'proposal' : 'command'}", :number=>self.number)
  end

  def taxes
    self.amount_with_taxes - self.amount
  end
  
  def sales_conditions
    c = []
    16.to_i.times do
      s = ''
      (rand*20+10).to_i.times { s += "w"*(2+rand*10)+" " }
      c << s.strip+"."
    end
    c
  end

end


